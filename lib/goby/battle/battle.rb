require 'goby'

module Goby
  # Representation of a fight between two Fighters.
  class Battle
    # @param [Entity] entity_a the first entity in the battle
    # @param [Entity] entity_b the second entity in the battle
    def initialize(entity_a, entity_b)
      @entity_a = entity_a
      @entity_b = entity_b
      @pair = [entity_a, entity_b]
    end

    # Determine the winner of the battle
    #
    # @return [Entity] the winner of the battle
    def determine_winner
      type("#{@entity_a.name} enters a battle with #{@entity_b.name}!\n\n")
      while @pair.none?(&:dead?)
        opening_pair = determine_opening_pair
        attacks = [opening_pair, opening_pair.reverse].map do |attacker, enemy|
          [attacker.choose_attack, attacker, enemy]
        end

        attacks.each do |attack, attacker, enemy|
          attack.run(attacker, enemy)

          if attacker.escaped
            attacker.escaped = false
            return
          end

          break if @pair.any?(&:dead?)
        end
      end
      winner = @pair.detect { |entity| !entity.dead? }
      loser = @pair.detect(&:dead?)
      winner.handle_victory(loser)
      loser.die
      winner
    end

    private

    def determine_opening_pair
      total_agility = @pair.sum { |entity| entity.stats[:agility] }
      Random.rand(0..total_agility - 1) < @entity_a.stats[:agility] ? @pair : @pair.reverse
    end
  end
end
