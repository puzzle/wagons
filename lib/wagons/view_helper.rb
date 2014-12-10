module Wagons
  module ViewHelper
    # Renders all partials with names that match "_[ key ]_*.[ format ].[ handler ]"
    # in alphabetical order.
    # Accepts an additional option :folder to pass an additional folder to search
    # extension partials in.
    def render_extensions(key, options = {})
      extensions = find_extension_partials(key, options.delete(:folder)).map do |partial|
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
      folders << folder.to_s if folder

      files = find_extension_files(key, folders).sort_by { |f| File.basename(f) }
      files_to_partial_names(files)
    end

    def find_extension_files(key, folders)
      folder_pattern = glob_pattern(folders.uniq)
      formats = glob_pattern(lookup_context.formats)
      handlers = glob_pattern(lookup_context.handlers)

      view_paths.map do |path|
        Dir.glob(File.join(path.to_s, folder_pattern, "_#{key}_*.#{formats}.#{handlers}"))
      end.flatten
    end

    def files_to_partial_names(files)
      files.map do |f|
        m = f.match(/views.(.+?[\/\\])_(.+)\.\w+\.\w+$/)
        m[1] + m[2]
      end
    end

    def glob_pattern(list)
      if list.size == 1
        list.first
      else
        "{#{list.join(',')}}"
      end
    end
  end
end

ActionView::Base.send(:include, Wagons::ViewHelper) if defined?(ActionView::Base)
