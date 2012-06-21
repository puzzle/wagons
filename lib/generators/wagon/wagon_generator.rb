class WagonGenerator < Rails::Generators::NamedBase #:nodoc:
  
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
    
    # do this whole manual traversal to be able to replace every single file
    # individually in the application.
    all_templates.each do |file|
      if File.basename(file) == '.empty_directory'
        file = File.dirname(file)
        directory(file, File.join(destination_root, file))
      else
        template(file, File.join(destination_root, file.sub(/\.tt$/, '')))
      end
    end
  end
  
  private
  
  def all_templates
    source_paths.collect do |path|
      Dir[File.join(path, "**", "{*,.[a-z]*}")].
          select {|f| File.file?(f) }.
          collect {|f| f.sub(path + File::SEPARATOR, '') }
    end.flatten.uniq.sort
  end
  
end
