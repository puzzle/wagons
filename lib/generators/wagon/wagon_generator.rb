class WagonGenerator < Rails::Generators::NamedBase
  
  attr_reader :wagon_name, :app_root_initializer
  
  source_root File.expand_path('../templates', __FILE__)
  
  def initialize(*args)
    super
    @wagon_name = name
    @app_root_initializer = "ENV['APP_ROOT'] ||= File.expand_path(__FILE__).split(\"vendor\#{File::SEPARATOR}wagons\").first"
    
    assign_names!("#{application_name}_#{name}")
  end
  
  
  def copy_templates
    self.destination_root = "vendor/wagons/#{wagon_name}" 
    directory('.')
  end
  
end
