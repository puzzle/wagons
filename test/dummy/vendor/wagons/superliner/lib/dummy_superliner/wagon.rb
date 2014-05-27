module DummySuperliner
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Add a load path for this specific Wagon
    # config.autoload_paths += %W( #{config.root}/lib )

    app_requirement '>= 1.0.0'

    config.to_prepare do
      # extend application classes here
      Person.belongs_to :city
    end
  end
end
