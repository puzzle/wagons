module Rails
  class Application < Engine
    protected

    # Append wagons at the end of all railties, even after the application.
    def ordered_railties_with_wagons
      @ordered_railties ||= ordered_railties_without_wagons.tap do |ordered|
        flat = Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new('4.1.6')
        Wagons.all.each do |w|
          if flat
            ordered.push(ordered.delete(w))
          else
            ordered.unshift(array_deep_delete(ordered, w))
          end
        end
      end
    end
    alias_method_chain :ordered_railties, :wagons

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
