require 'goby'

module Goby

  # Extends upon Entity by providing a location in the
  # form of a Map and a pair of y-x location. Overrides
  # some methods to accept input during battle.
  class Player < Entity

    include WorldCommand
    include Fighter

    # Default location when no "good" map & location specified.
    DEFAULT_LOCATION = Location.new(Map.new(tiles: [[Tile.new]]), C[0, 0])

    # distance in each direction that tiles are acted upon
    # used in: update_map, print_minimap
    VIEW_DISTANCE = 2

    # @param [String] name the name.
    # @param [Hash] stats hash of stats
    # @param [[C(Item, Integer)]] inventory a list of pairs of items and their respective amounts.
    # @param [Integer] gold the currency used for economical transactions.
    # @param [[BattleCommand]] battle_commands the commands that can be used in battle.
    # @param [Hash] outfit the collection of equippable items currently worn.
    # @param [Location] location the place at which the player should start.
    # @param [Location] respawn_location the place at which the player respawns.
    def initialize(name: "Player", stats: {}, inventory: [], gold: 0, battle_commands: [],
                   outfit: {}, location: nil, respawn_location: nil)
      super(name: name, stats: stats, inventory: inventory, gold: gold, outfit: outfit)
      @saved_maps = {}

      add_battle_commands(battle_commands)
      move_to(location&.existent_and_passable? ? location : DEFAULT_LOCATION)

      @respawn_location = respawn_location || @location
      @saved_maps = {}
    end

    # Uses player input to determine the battle command.
    #
    # @return [BattleCommand] the chosen battle command.
    def choose_attack
      command, input = determine_battle_command("Choose an attack:")
      until command
        puts "You don't have '#{input}'"
        command, input = determine_battle_command("Try one of these:")
      end
      command
    end

    # Requires input to select item and on whom to use it
    # during battle (Use command). Return nil on error.
    #
    # @param [Entity] enemy the opponent in battle.
    # @return [C(Item, Entity)] the item and on whom it is to be used.
    def choose_item_and_on_whom(enemy)
      item = nil

      # Choose the item to use.
      until item
        print_inventory
        input = passable_input('Which item would you like to use?')
        return unless input

        item = find_item(input)
        print NO_SUCH_ITEM_ERROR unless item
      end

      whom = nil

      # Choose on whom to use the item.
      until whom
        input = passable_input("On whom will you use the item (#{@name} or #{enemy.name})?")
        return unless input

        whom = [self, enemy].detect { |player|  input.casecmp?(player.name) }
        print "What?! Choose either #{@name} or #{enemy.name}!\n\n" unless whom
      end

      C[item, whom]
    end

    # Sends the player back to a safe location,
    # halves its gold, and restores HP.
    def die
      sleep(2) unless ENV['TEST']

      move_to(@respawn_location)
      type("After being knocked out in battle,\n")
      type("you wake up in #{@location.map.name}.\n\n")

      sleep(2) unless ENV['TEST']

      # Heal the player.
      set_stats(hp: @stats[:max_hp])
    end

    # Retrieve loot obtained by defeating the enemy.
    #
    # @param [Fighter] fighter the Fighter who lost the battle.
    def handle_victory(fighter)
      type("#{@name} defeated the #{fighter.name}!\n")
      gold = fighter.sample_gold
      treasure = fighter.sample_treasures
      add_loot(gold, [treasure]) if gold || treasure

      type("Press enter to continue...")
      player_input
    end

    # Moves the player down. Increases 'y' coordinate by 1.
    def move_down
      move_to_tile(C[@location.coords.first + 1, @location.coords.second])
    end

    # Moves the player left. Decreases 'x' coordinate by 1.
    def move_left
      move_to_tile(C[@location.coords.first, @location.coords.second - 1])
    end

    # Moves the player right. Increases 'x' coordinate by 1.
    def move_right
      move_to_tile(C[@location.coords.first, @location.coords.second + 1])
    end

    # Safe setter function for location and map.
    #
    # @param [Location] location the new location.
    def move_to(location)

      map = location.map

      # Prevents operations on nil.
      return if map.nil?

      # Save the map.
      @saved_maps[@location.map.name] = @location.map if @location

      # Even if the player hasn't moved, we still change to true.
      # This is because we want to re-display the minimap anyway.
      @moved = true

      # Prevents moving onto nonexistent and impassable tiles.
      return unless location.existent_and_passable?

      # Update the location and surrounding tiles.
      @location = Location.new(@saved_maps[map.name] || map, location.coords)
      update_map

      tile = @location.map.tiles[location.coords.first][location.coords.second]
      # 50% chance to encounter monster (TODO: too high?)
      battle(tile.monsters.sample.clone) if tile.monsters.any? && [true, false].sample
    end

    # Moves the player up. Decreases 'y' coordinate by 1.
    def move_up
      move_to_tile(C[@location.coords.first - 1, @location.coords.second])
    end

    # Prints the map in regards to what the player has seen.
    # Additionally, provides current location and the map's name.
    def print_map

      # Provide some spacing from the edge of the terminal.
      3.times { print " " };

      print @location.map.name + "\n\n"

      @location.map.tiles.each_with_index do |row, r|
        # Provide spacing for the beginning of each row.
        2.times { print " " }

        row.each_with_index do |tile, t|
          print_tile(C[r, t])
        end
        print "\n"
      end

      print "\n"

      # Provide some spacing to center the legend.
      3.times { print " " }

      # Prints the legend.
      print "¶ - #{@name}'s\n       location\n\n"
    end

    # Prints a minimap of nearby tiles (using VIEW_DISTANCE).
    def print_minimap
      print "\n"
      nearby_tiles(@location.coords.first).each do |y|
        # centers minimap
        10.times { print " " }
        nearby_tiles(@location.coords.second).select { |x| @location.map.in_bounds(y, x) }.each do |x|
          print_tile(C[y, x])
        end
        # new line if this row is not out of bounds
        print "\n" if y < @location.map.tiles.size
      end
      print "\n"
    end

    # Prints the tile based on the player's location.
    #
    # @param [C(Integer, Integer)] coords the y-x location of the tile.
    def print_tile(coords)
       print (@location.coords == coords) ? "¶ " : @location.map.tiles[coords.first][coords.second].to_s
    end

    # Updates the 'seen' attributes of the tiles on the player's current map.
    #
    # @param [Location] location to update seen attribute for tiles on the map.
    def update_map(location = @location)
      nearby_tiles(location.coords.first).each do |y|
        nearby_tiles(location.coords.second).select { |x| @location.map.in_bounds(y, x) }.each do |x|
          @location.map.tiles[y][x].seen = true
        end
      end
    end

    # The treasure given by a Player after losing a battle.
    #
    # @return [Item] the reward for the victor of the battle (or nil - no treasure).
    def sample_treasures
      nil
    end

    # Returns the gold given to a victorious Entity after losing a battle
    # and deducts the figure from the Player's total as necessary
    #
    # @return[Integer] the amount of gold to award the victorious Entity
    def sample_gold
      gold_lost = 0
      # Reduce gold if the player has any.
      if @gold.positive?
        type("Looks like you lost some gold...\n\n")
        gold_lost = @gold/2
        @gold -= gold_lost
      end
      gold_lost
    end

    def tile
      location.map.tiles[location.coords.first][location.coords.second]
    end

    def visible_events
      tile.events.select(&:visible)
    end

    attr_reader :location
    attr_accessor :moved, :respawn_location

    private

    def nearby_tiles(axis)
      ((axis - VIEW_DISTANCE)..(axis + VIEW_DISTANCE)).reject(&:negative?)
    end

    def move_to_tile(tile)
      move_to(Location.new(@location.map, tile))
    end

    def passable_input(question)
      puts question
      input = player_input prompt: "(or type 'pass' to forfeit the turn): "
      input.casecmp?('pass') ? nil : input
    end

    def determine_battle_command(header)
      print_battle_commands(header = header)
      input = player_input
      return find_battle_command(input), input
    end
  end

end
