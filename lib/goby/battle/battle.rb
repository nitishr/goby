require 'goby'

module Goby
  # Representation of a fight between two Fighters.
  class Battle
    # @param [Entity] entity_a the first entity in the battle
    # @param [Entity] entity_b the second entity in the battle
    def initialize(entity_a, entity_b)
      @pair = [entity_a, entity_b]
    end

    # Determine the winner of the battle
    #
    # @return [Entity] the winner of the battle
    def determine_winner
      type("#{@pair.first.name} enters a battle with #{@pair.last.name}!\n\n")
      fight_to_finish_or_escape

      return if @pair.none?(&:dead?)

      loser, winner = @pair.partition(&:dead?).flatten
      winner.handle_victory(loser)
      loser.die
      winner
    end

    private

    def fight_to_finish_or_escape
      while @pair.none?(&:dead?)
        choose_attacks(determine_opening_pair).each do |attack, attacker, enemy|
          attack.run(attacker, enemy)
          if attacker.escaped
            attacker.escaped = false
            return
          end
          return if @pair.any?(&:dead?)
        end
      end
    end

    def choose_attacks(opening_pair)
      [opening_pair, opening_pair.reverse].map do |attacker, enemy|
        [attacker.choose_attack, attacker, enemy]
      end
    end

    def determine_opening_pair
      total_agility = @pair.sum { |entity| entity.stats[:agility] }
      Random.rand(0..total_agility - 1) < @pair.first.stats[:agility] ? @pair : @pair.reverse
    end
  end
end
