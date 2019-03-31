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
      prev_item = entity.outfit[type]

      entity.outfit[type] = self
      entity.alter_stats(self, true)

      if prev_item
        entity.alter_stats(prev_item, false)
        entity.add_item(prev_item)
      end

      print "#{entity.name} equips #{@name}!\n\n"
    end

    # Unequips from the entity and changes the entity's attributes accordingly.
    #
    # @param [Entity] entity the entity who is unequipping the equippable.
    def unequip(entity)
      entity.outfit.delete(type)
      entity.alter_stats(self, false)

      print "#{entity.name} unequips #{@name}!\n\n"
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
