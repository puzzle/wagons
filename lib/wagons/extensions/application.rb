module Rails
  class Application < Engine
    
    protected

    # Append wagons at the end of all railties, even after the application.
    def ordered_railties_with_wagons
      @ordered_railties ||= ordered_railties_without_wagons.tap do |ordered|
        Wagons.all.each do |w|
          ordered.push(ordered.delete(w))
        end
      end
    end
    
    alias_method_chain :ordered_railties, :wagons
    
  end
end