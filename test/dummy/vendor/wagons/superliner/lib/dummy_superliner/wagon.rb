module DummySuperliner
  class Wagon < Rails::Engine
    include ::Wagon
    
    # Add a load path for this specific Wagon
    #config.autoload_paths += %W( #{config.root}/lib )

    config.to_prepare do
      # extend application classes here
    end 
  
  end
end
