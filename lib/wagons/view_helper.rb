module Wagons
  module ViewHelper
     
    # Renders all partials with names that match "_[ key ]_*.[ format ].[ handler ]"
    # in alphabetical order.
    # Accepts an additional option :folder to pass an additional folder to search
    # extension partials in.
    def render_extensions(key, options = {})
      extensions = find_extension_partials(key, options.delete(:folder)).collect do |partial|
        render options.merge(:partial => partial) 
      end
      safe_join(extensions)
    end
    
    # The view folders relative to app/views in which extensions are searched for.
    # Uses the folder of the current template.
    def extension_folders
      [current_template_folder]
    end
    
    # The folder of the current partial relative to app/views
    def current_template_folder
      @virtual_path[/(.+)\/.*/, 1]
    end
    
    private
    
    def find_extension_partials(key, folder = nil)
      folders = extension_folders.dup
      folders << folder if folder
      
      files = find_extension_files(key, folders).sort_by { |f| File.basename(f) }
      files_to_partial_names(files)
    end
    
    def find_extension_files(key, folders)
      view_paths.collect do |path|
        folders.collect do |folder|
          lookup_context.formats.collect do |format|
            lookup_context.handlers.collect do |handler|
              Dir.glob(File.join(path, folder, "_#{key}_*.#{format}.#{handler}"))
            end
          end
        end
      end.flatten
    end
    
    def files_to_partial_names(files)
      files.collect do |f|
        m = f.match(/views.(.+?[\/\\])_(.+)\.\w+\.\w+$/)
        m[1] + m[2]
      end
    end
      
  end
end

ActionView::Base.send(:include, Wagons::ViewHelper) if defined?(ActionView::Base)