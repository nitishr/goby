require 'goby'

module Goby
  class Outfit
    extend Forwardable

    def_delegators :@outfit, :[], :[]=, :values, :delete, :==, :empty?

    def initialize
      @outfit = {}
    end

    def format_equipments
      %i[weapon shield helmet torso legs].sum('') { |equipment|
        "* #{equipment.to_s.capitalize}: #{@outfit[equipment]&.name || 'none'}\n"
      }
    end
  end

  # Provides the ability to fight, equip/unequip weapons & armor,
  # and carry items & gold.
  class Entity
    extend Forwardable

    def_delegators :@inventory, :add_item, :find_item, :remove_item

    # Error when the entity specifies a non-existent item.
    NO_SUCH_ITEM_ERROR = "What?! You don't have THAT!\n\n".freeze
    # Error when the entity specifies an item not equipped.
    NOT_EQUIPPED_ERROR = "You are not equipping THAT!\n\n".freeze

    # @param [String] name the name.
    # @param [Hash] stats hash of stats
    # @option stats [Integer] :max_hp maximum health points. Set to be positive.
    # @option stats [Integer] :hp current health points. Set to be nonnegative.
    # @option stats [Integer] :attack strength in battle. Set to be positive.
    # @option stats [Integer] :defense protection from attacks. Set to be positive.
    # @option stats [Integer] :agility speed of commands in battle. Set to be positive.
    # @param [[C(Item, Integer)]] inventory a list of pairs of items and their respective amounts.
    # @param [Integer] gold the currency used for economical transactions.
    # @param [[Equippable]] outfit the collection of equippable items currently worn.
    def initialize(name: 'Entity', stats: {}, inventory: [], gold: 0, outfit: [])
      @name = name
      set_stats(stats)
      @inventory = Goby::Inventory.new(inventory)
      set_gold(gold)

      # See its attr_accessor below.
      @outfit = Goby::Outfit.new
      outfit.each do |value|
        value.equip(self)
      end

      # This should only be switched to true during battle.
      @escaped = false
    end

    # Adjusts gold by the given amount.
    # Entity's gold will not be less than zero.
    #
    # @param [Integer] amount the amount of gold to adjust by.
    def adjust_gold_by(amount)
      set_gold(@gold + amount)
    end

    # Adds the specified gold and treasures to the inventory.
    #
    # @param [Integer] gold the amount of gold.
    # @param [[Item]] treasures the list of treasures.
    def add_loot(gold, treasures)
      (treasures ||= []).compact!
      type('Loot: ')
      if gold.positive? || treasures.any?
        print "\n"
        if gold.positive?
          type("* #{gold} gold\n")
          adjust_gold_by(gold)
        end
        treasures.each do |treasure|
          type("* #{treasure.name}\n")
          add_item(treasure)
        end
        print "\n"
      else
        type("nothing!\n\n")
      end
    end

    # Removes all items from the entity's inventory.
    def clear_inventory
      @inventory.clear
    end

    def drop_item(name)
      item = find_item(name)
      if item
        if item.disposable
          # TODO: Perhaps the player should be allowed to specify
          #       how many of the Item to drop.
          remove_item(item, 1)
          print "You have dropped #{item}.\n\n"
        else
          print "You cannot drop that item.\n\n"
        end
      else
        print NO_ITEM_DROP_ERROR
      end
    end

    # Equips the specified item to the entity's outfit.
    #
    # @param [Item, String] item the item (or its name) to equip.
    def equip_item(item)
      actual_item = find_item(item)
      if actual_item
        # Checks for Equippable without importing the file.
        if defined? actual_item.equip
          actual_item.equip(self)

          # Equipping the item will always remove it from the entity's inventory.
          remove_item(actual_item)
        else
          print "#{actual_item.name} cannot be equipped!\n\n"
        end
      else
        print NO_SUCH_ITEM_ERROR
      end
    end

    # Returns the index of the specified item, if it exists.
    #
    # @param [Item, String] item the item (or its name).
    # @return [Integer] the index of an existing item. Otherwise nil.
    def inventory_entry(item)
      @inventory.entry(item)
    end

    # Prints the inventory in a nice format.
    def print_inventory
      print "Current gold in pouch: #{@gold}.\n\n"
      print "#{@name}'s inventory"
      print @inventory.empty? ? ' is empty!' : ":#{@inventory.format_items}"
      print "\n\n"
    end

    # Prints the status in a nice format.
    def print_status
      puts 'Stats:'
      puts "* HP: #{@stats[:hp]}/#{@stats[:max_hp]}"
      %i[attack defense agility].each do |stat|
        puts "* #{stat.to_s.capitalize}: #{@stats[stat]}"
      end
      print "\n"

      puts 'Equipment:'
      puts outfit.format_equipments
      print "\n"
    end

    # Sets the Entity's gold to the number in the argument.
    # Only nonnegative numbers are accepted.
    #
    # @param [Integer] gold the amount of gold to set.
    def set_gold(gold)
      @gold = [gold, 0].max
    end

    # Sets stats
    #
    # @param [Hash] passed_in_stats value pairs of stats
    # @option passed_in_stats [Integer] :max_hp maximum health points. Set to be positive.
    # @option passed_in_stats [Integer] :hp current health points. Set to be nonnegative.
    # @option passed_in_stats [Integer] :attack strength in battle. Set to be positive.
    # @option passed_in_stats [Integer] :defense protection from attacks. Set to be positive.
    # @option passed_in_stats [Integer] :agility speed of commands in battle. Set to be positive.
    def set_stats(passed_in_stats)
      @stats ||= { max_hp: 1, hp: nil, attack: 1, defense: 1, agility: 1 }
      stats = @stats.merge(passed_in_stats)

      # Set hp to max_hp if hp not specified
      stats[:hp] ||= stats[:max_hp]
      # hp should not be greater than max_hp and be at least 0
      stats[:hp] = [[stats[:hp], stats[:max_hp]].min, 0].max
      # ensure all other stats > 0
      stats.each do |key, value|
        if %i[max_hp attack defense agility].include?(key)
          stats[key] = [value, 1].max
        end
      end

      @stats = stats
    end

    # getter for stats
    #
    # @return [Object]
    def stats
      # attr_reader makes sure stats cannot be set via stats=
      # freeze makes sure that stats []= cannot be used
      @stats.freeze
    end

    # Unequips the specified item from the entity's outfit.
    #
    # @param [Item, String] item the item (or its name) to unequip.
    def unequip_item(item)
      item = @outfit.values.detect { |value| value.name.casecmp?(item.to_s) }
      if item
        item.unequip(self)
        add_item(item)
      else
        print NOT_EQUIPPED_ERROR
      end
    end

    # Uses the item, if it exists, on the specified entity.
    #
    # @param [Item, String] item the item (or its name) to use.
    # @param [Entity] entity the entity on which to use the item.
    def use_item(item, entity)
      actual_item = find_item(item)
      if actual_item
        actual_item.use(self, entity)
        remove_item(actual_item) if actual_item.consumable
      else
        print NO_SUCH_ITEM_ERROR
      end
    end

    # @param [Entity] rhs the entity on the right.
    def ==(rhs)
      @name == rhs.name
    end

    def dead?
      @stats[:hp] <= 0
    end

    # Alters the stats
    #
    # @param [Equippable] equippable the item being equipped/unequipped.
    # @param [Boolean] equipping flag for when the item is being equipped or unequipped.
    # @todo ensure stats cannot go below zero (but does it matter..?).
    def alter_stats(equippable, equipping)
      stats_to_change = stats.dup
      operator = equipping ? 1 : -1
      %i[attack defense agility max_hp].each do |stat|
        stats_to_change[stat] += (operator * equippable.stat_change[stat]) if equippable.stat_change[stat]
      end

      set_stats(stats_to_change)

      # do not kill entity by unequipping
      set_stats(hp: 1) if stats[:hp] < 1
    end

    def equip(equippable)
      prev_item = outfit[equippable.type]

      outfit[equippable.type] = equippable
      alter_stats(equippable, true)

      if prev_item
        alter_stats(prev_item, false)
        add_item(prev_item)
      end

      print "#{name} equips #{equippable.name}!\n\n"
    end

    def unequip(equippable)
      outfit.delete(equippable.type)
      alter_stats(equippable, false)

      print "#{name} unequips #{equippable.name}!\n\n"
    end

    attr_accessor :escaped, :inventory, :name
    attr_reader :gold, :outfit
  end
end
