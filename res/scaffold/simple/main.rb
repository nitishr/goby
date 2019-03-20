require 'goby'

include Goby

require_relative 'map/farm.rb'

# Set of all known positive responses.
POSITIVE_RESPONSES = Set.new %w[ok okay sure y ye yeah yes]

# Set this to true in order to use BGM.
Music.set_playback(false)

# By default, we've included no music files.
# The Music module also includes a function
# to change the music-playing program.

# Clear the terminal.
system('clear')

# Allow the player to load an existing game.
if File.exist?('player.yaml')
  print 'Load the saved file?: '
  player = load_game('player.yaml') if POSITIVE_RESPONSES.include?(player_input)
end

# No load? Create a new player.
run_driver(player || Player.new(location: Location.new(Farm.new, C[1, 1])))
