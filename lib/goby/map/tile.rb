module Goby
  # Describes a single location on a Map. Can have Events and Monsters.
  # Provides variables that control its graphical representation on the Map.
  class Tile
    # Default graphic for passable tiles.
    DEFAULT_PASSABLE = '·'.freeze
    # Default graphic for impassable tiles.
    DEFAULT_IMPASSABLE = '■'.freeze

    # @param [Boolean] passable if true, the player can move here.
    # @param [Boolean] seen if true, it will be printed on the map.
    # @param [String] description a summary/message of the contents.
    # @param [[Event]] events the events found on this tile.
    # @param [[Monster]] monsters the monsters found on this tile.
    # @param [String] graphic the respresentation of this tile graphically.
    def initialize(passable: true, seen: false, description: '', events: [], monsters: [], graphic: nil)
      @passable = passable
      @seen = seen
      @description = description
      @events = events
      @monsters = monsters
      @graphic = graphic || (@passable ? DEFAULT_PASSABLE : DEFAULT_IMPASSABLE)
    end

    # Create deep copy of Tile.
    #
    # @return Tile a new Tile object
    def clone
      Marshal.load(Marshal.dump(self))
    end

    # Convenient conversion to String.
    #
    # @return [String] the string representation.
    def to_s
      @seen ? @graphic + ' ' : '  '
    end

    attr_accessor :passable, :seen, :description, :events, :monsters, :graphic
  end
end
