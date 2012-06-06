module Wagons
  # Integrate tasks into Rails.
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/wagons.rake"
    end
  end
end