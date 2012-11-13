module Rails
  class Application
    protected

    # Append wagons at the end of all railties, even after the application.
    def ordered_railties
      @ordered_railties ||= super.tap do |ordered|
        Wagons.all.each do |w|
          ordered.push(ordered.delete(w))
        end
      end
    end
  end
end