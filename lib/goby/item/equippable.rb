module Goby
  # Provides methods for equipping & unequipping an Item.
  module Equippable
    # The function that returns the type of the item.
    # Subclasses must override this function.
    #
    def stat_change
      raise(NotImplementedError, 'An Equippable Item must implement a stat_change Hash')
    end

    # The function that returns the change in stats for when the item is equipped.
    # Subclasses must override this function.
    #
    def type
      raise(NotImplementedError, 'An Equippable Item must have a type')
    end

    # Equips onto the entity and changes the entity's attributes accordingly.
    #
    # @param [Entity] entity the entity who is equipping the equippable.
    def equip(entity)
      entity.equip(self)
    end

    # Unequips from the entity and changes the entity's attributes accordingly.
    #
    # @param [Entity] entity the entity who is unequipping the equippable.
    def unequip(entity)
      entity.unequip(self)
    end

    # The function that executes when one uses the equippable.
    #
    # @param [Entity] user the one using the item.
    # @param [Entity] entity the one on whom the item is used.
    def use(user, entity)
      print "Type 'equip #{@name}' to equip this item.\n\n"
    end
  end
end
