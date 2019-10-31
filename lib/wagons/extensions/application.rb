module Rails
  class Application < Engine
    protected

    # Append wagons at the end of all railties, even after the application.
    def ordered_railties_with_wagons
      @ordered_railties ||= ordered_railties_without_wagons.tap do |ordered|
        Wagons.all.each do |w|
          ordered.unshift(array_deep_delete(ordered, w))
        end
      end
    end
    alias ordered_railties_without_wagons ordered_railties
    alias ordered_railties ordered_railties_with_wagons

    private

    def array_deep_delete(array, item)
      array.delete(item) ||
      array.select  { |i| i.is_a?(Array) }.
            collect { |i| array_deep_delete(i, item) }.
            compact.
            first
    end

  end
end
