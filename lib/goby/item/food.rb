require 'goby'

module Goby
  # Recovers HP when used.
  class Food < Item
    # @param [String] name the name.
    # @param [Integer] price the cost in a shop.
    # @param [Boolean] consumable upon use, the item is lost when true.
    # @param [Boolean] disposable allowed to sell or drop item when true.
    # @param [Integer] recovers the amount of HP recovered when used.
    def initialize(name: 'Food', price: 0, consumable: true, disposable: true, recovers: 0)
      super(name: name, price: price, consumable: consumable, disposable: disposable)
      @recovers = recovers
    end

    # Heals the entity.
    #
    # @param [Entity] user the one using the food.
    # @param [Entity] entity the one on whom the food is used.
    def use(user, entity)
      max_possible_recovery = entity.stats[:max_hp] - entity.stats[:hp]
      this_recover = [max_possible_recovery, @recovers].min
      entity.set_stats(hp: (entity.stats[:hp] + this_recover))

      # Helpful output.
      print "#{user.name} uses #{name}"
      print user == entity ? ' and ' : " on #{entity.name}!\n#{entity.name} "
      print "recovers #{this_recover} HP!\n\n"
      print "#{entity.name}'s HP: #{entity.stats[:hp]}/#{entity.stats[:max_hp]}\n\n"
    end

    # The amount of HP that the food recovers.
    attr_reader :recovers
  end
end
