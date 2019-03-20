module Goby
  # A 2D arrangement of Tiles. The Player can move around on it.
  class Map
    # @param [String] name the name.
    # @param [[Tile]] tiles the content of the map.
    def initialize(name: 'Map', tiles: [[Tile.new]], music: nil)
      @name = name
      @tiles = tiles
      @music = music
    end

    # Returns true when @tiles[y][x] is an existing index of @tiles.
    # Otherwise, returns false.
    #
    # @param [Integer] y the y-coordinate.
    # @param [Integer] x the x-coordinate.
    # @return [Boolean] the existence of the tile.
    def in_bounds(y, x)
      y.nonnegative? && y < @tiles.length && x.nonnegative? && x < @tiles[y].length
    end

    def existent_and_passable?(coords)
      in_bounds(coords.first, coords.second) && tiles[coords.first][coords.second].passable
    end

    # Prints the map in a nice format.
    def to_s
      @tiles.flat_map { |row| row.map(&:graphic) }.join(' ') + " \n"
    end

    # @param [Map] rhs the Map on the right.
    def ==(rhs)
      @name == rhs.name
    end

    attr_accessor :name, :tiles, :music
  end
end
