require 'readline'
require 'yaml'

# Collection of classes, modules, and functions that make
# up the Goby framework.
module Goby
  # Stores a pair of values as a couple.
  class C
    # Syntactic sugar to create a couple using C[a, b]
    #
    # @param [Object] first the first object in the pair.
    # @param [Object] second the second object in the pair.
    def self.[](first, second)
      C.new(first, second)
    end

    # @param [Object] first the first object in the pair.
    # @param [Object] second the second object in the pair.
    def initialize(first, second)
      @first = first
      @second = second
    end

    # @param [C] rhs the couple on the right.
    def ==(rhs)
      (@first == rhs.first) && (@second == rhs.second)
    end

    attr_accessor :first, :second
  end

  # The combination of a map and y-x coordinates,
  # which determine a specific position/location on the map.
  class Location
    # Location constructor.
    #
    # @param [Map] map the map component.
    # @param [C(Integer, Integer)] coords a pair of y-x coordinates.
    def initialize(map, coords)
      @map = map
      @coords = coords
    end

    def existent_and_passable?
      coords && map&.existent_and_passable?(coords)
    end

    def ==(other)
      map == other.map && coords == other.coords
    end

    attr_reader :map, :coords
  end

  # Simple player input script.
  #
  # @param [Boolean] lowercase mark true if response should be returned lowercase.
  # @param [String] prompt the prompt for the user to input information.
  # @param [Boolean] doublespace mark false if extra space should not be printed after input.
  def player_input(lowercase: true, prompt: '', doublespace: true)
    # When using Readline, rspec actually prompts the user for input, freezing the tests.
    print prompt
    input = ENV['TEST'] == 'rspec' ? gets.chomp : Readline.readline(" \b", false)
    puts "\n" if doublespace

    if (input.size > 1) && (input != Readline::HISTORY.to_a[-1])
      Readline::HISTORY.push(input)
    end

    lowercase ? input.downcase : input
  end

  # Prints text as if it were being typed.
  #
  # @param [String] message the message to type out.
  def type(message)
    # Sleep between printing of each char.
    message.split('').each do |i|
      sleep(0.015) unless ENV['TEST']
      print i
    end
  end

  # Serializes the player object into a YAML file and saves it
  #
  # @param [Player] player the player object to be saved.
  # @param [String] filename the name under which to save the file.
  def save_game(player, filename)
    # Set 'moved' to true so we see minimap on game load.
    player.moved = true
    File.open(filename, 'w') do |file|
      file.puts YAML.dump(player)
    end
    player.moved = false
    print "Successfully saved the game!\n\n"
  end

  # Reads and check the save file and parses into the player object
  #
  # @param [String] filename the file containing the save data.
  # @return [Player] the player corresponding to the save data.
  def load_game(filename)
    YAML.load_file(filename)
  rescue StandardError
    nil
  end
end
