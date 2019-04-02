module Goby
  class Inventory
    include Enumerable
    extend Forwardable

    def_delegators :@items, :each, :empty?, :size

    def initialize(items)
      @items = items
    end

    def entry(item)
      @items.detect { |couple| couple.first.name.casecmp?(item.to_s) }
    end

    def find_item(item)
      entry(item)&.first
    end

    # Adds the item and the given amount to the inventory.
    #
    # @param [Item] item the item being added.
    # @param [Integer] amount the amount of the item to add.
    def add_item(item, amount = 1)
      found = entry(item)
      if found
        found.second += amount
      else
        @items.push(C[item, amount])
      end
    end

    # Removes the item, if it exists, and, at most, the given amount from the inventory.
    #
    # @param [Item] item the item being removed.
    # @param [Integer] amount the amount of the item to remove.
    def remove_item(item, amount = 1)
      couple = entry(item)
      if couple
        couple.second -= amount
        @items.delete(couple) if couple.second <= 0
      end
    end

    def random_item
      @items.sample.first
    end

    def clear
      @items = []
    end

    def format_items
      @items.sum('') {|couple| "\n* #{couple.first.name} (#{couple.second})"}
    end
  end
end