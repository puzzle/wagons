class WagonGenerator < Rails::Generators::NamedBase #:nodoc:
  attr_reader :wagon_name

  source_root File.expand_path('../templates', __FILE__)

  def initialize(*args)
    super
    @wagon_name = name
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
    source_paths.map do |path|
      Dir[File.join(path, '**', '{*,.[a-z]*}')].
          select { |f| File.file?(f) }.
          map { |f| f.sub(path + File::SEPARATOR, '') }
    end.flatten.uniq.sort
  end
end
