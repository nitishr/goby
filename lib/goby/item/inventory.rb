module Goby
  class Inventory
    include Enumerable
    extend Forwardable

    def_delegators :@items, :each, :empty?, :size

    def initialize(items)
      @items = items
    end

    def entry(item)
      @items.detect {|couple| couple.first.name.casecmp?(item.to_s)}
    end

    def find_item(item)
      entry(item)&.first
    end

    def add_item(item, amount = 1)
      found = entry(item)
      if found
        found.second += amount
      else
        @items.push(C[item, amount])
      end
    end

    def clear
      @items = []
    end

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

    def format_items
      @items.sum('') {|couple| "\n* #{couple.first.name} (#{couple.second})"}
    end

    def ==(other)
      @items == other
    end
  end
end