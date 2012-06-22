require 'open3'

module Wagons
  
  # Helper class to install wagons into the current application.
  # Wagons are searched for in the system gem repository.
  #
  # If you want to use the #install method, add "gem 'open4'" to
  # your Gemfile.
  class Installer
    class << self
      # Gem specifications of all installed wagons.
      def installed
        @installed ||= Wagons.all.collect(&:gemspec)
      end
  
      # Most recent gem specifications of all wagons available in GEM_HOME.
      def available
        return @available if defined?(@available)
  
        # only keep most recent version in @available
        @available = []
        load_available_specs.each do |spec|
          if prev = @available.find {|w| w.name == spec.name }
            if prev.version < spec.version
            @available.delete(prev)
            @available << spec
            end
          else
          @available << spec
          end
        end
        @available
      end
  
  
      # Most recent gem specifications of available, but not installed (in any version) wagons.
      def not_installed
        exclude_specs(available, installed)
      end
  
      # Most recent gem specifications of available and installed (in an older version) wagons.
      def updates
        available.select do |spec|
          if wagon = installed_spec(spec.name)
            wagon.version < spec.version
          end
        end
      end
  
      # Install or update the wagons with the given names. I.e., adds the given
      # wagon names to the Wagonfile and runs rake wagon:setup.
      # After that, the application MUST be restarted to load the new wagons.
      # Returns nil if everything is fine or a string with error messages.
      # This method requires open4.
      def install(names)
        change_internal(names, :check_dependencies) do |specs|
          content = File.read(wagonfile) rescue ""
          wagonfile_update(specs)
          
          begin
            setup_wagons(specs)
          rescue => e
            wagonfile_write(content)
            raise e
          end
        end
      end
  
      # Remove the wagons with the given names. I.e., reverts the migrations
      # of the given wagon names if the wagon is not protected 
      # and removes the entries from the Wagonfile.
      # Returns nil if everything is fine or a string with error messages.
      def uninstall(names)
        change_internal(names, :check_uninstalled_dependencies, :check_protected) do |specs|
          remove_wagons(specs)
          wagonfile_remove(specs)
        end
      end
  
      # Get the gem specification of the installed wagon with the given name.
      # Return nil if not found.
      def installed_spec(name)
        installed.find {|s| s.name == name }
      end
  
      # Get the gem specification of an available wagon with the given name.
      # Return nil if not found.
      def available_spec(name)
        available.find {|s| s.name == name}
      end
      
      # Update the Wagonfile with the given gem specifications.
      def wagonfile_update(specs)
        wagonfile_edit(specs) do |spec, content|
          declaration = "gem '#{spec.name}', '#{spec.version.to_s}'"
          unless content.sub!(gem_declaration_regexp(spec.name), declaration)
            content += "\n#{declaration}"
          end
          content
        end
      end
  
      # Remove the given gem specifications from the Wagonfile.
      def wagonfile_remove(specs)
        wagonfile_edit(specs) do |spec, content|
          content.sub(gem_declaration_regexp(spec.name), '')
        end
      end
      
      # Check if all wagon dependencies of the given gem specifications
      # are met by the installed wagons.
      # Returns nil if everything is fine or a string with error messages.
      def check_dependencies(specs)
        missing = check_app_requirement(specs)
  
        present = exclude_specs(installed, specs)
        future = present + specs
  
        check_all_dependencies(specs, future, missing)
      end
      
      # Check if the app requirement of the given gem specifications
      # are met by the current app version.
      # Returns nil if everything is fine or a array with error messages.
      def check_app_requirement(specs)
        missing = []
        specs.each do |spec|
          if wagon = wagon_class(spec)
            unless wagon.app_requirement.satisfied_by?(Wagons.app_version)
              missing << "#{spec} requires application version #{wagon.app_requirement}"
            end
          end
        end
  
        missing
      end
      
      # Check if the wagon dependencies of the remaining wagons
      # would still be met after the given gem specifications are uninstalled.
      # Returns nil if everything is fine or a string with error messages.
      def check_uninstalled_dependencies(specs)
        present = exclude_specs(installed, specs)
        check_all_dependencies(present, present)
      end
  
      # Checks if the wagons for given gem specifications are protected.
      # Returns nil if everything is fine or a string with error messages.
      def check_protected(specs)
        protected = []
        specs.each do |spec|
          msg = Wagons.find(spec.name).protect?
          protected << msg if msg.is_a?(String)
        end
        protected.join("\n").presence
      end
  
      # List of available gem specifications with the given names.
      # Raises an error if a name cannot be found.
      def specs_from_names(names)
        names.collect do |name| 
          spec = available_spec(name)
          raise "#{name} was not found" if spec.nil?
          spec
        end
      end
      
      # Removes all gem specifications with the same name in to_be_excluded from full.
      # Versions are ignored.
      def exclude_specs(full, to_be_excluded)
        full.clone.delete_if {|s| to_be_excluded.find {|d| s.name == d.name } }
      end
      
      # Wagonfile
      def wagonfile
        Rails.root.join("Wagonfile")
      end
      
      # The wagon class of the given spec.
      def wagon_class(spec)
        @wagon_classes ||= {}
        return @wagon_classes[spec] if @wagon_classes.has_key?(spec)
        
        clazz = nil
        file = File.join(spec.gem_dir, 'lib', spec.name, 'wagon.rb')
        if File.exists?(file)
          require file
          clazz = "#{spec.name.camelize}::Wagon".constantize
        else
          raise "#{spec.name} wagon class not found in #{file}"
        end
        @wagon_classes[spec] = clazz
      end
  
      private
      
      def load_available_specs
        paths = [ENV['GEM_HOME']]
        paths += (ENV['GEM_PATH'] || "").split(File::PATH_SEPARATOR)
        paths.collect(&:presence).compact.collect do |path|
          Dir[File.join(path, 'specifications', "#{Wagons.app_name}_*.gemspec")].collect do |gemspec|
            Gem::Specification.load(gemspec)
          end
        end.flatten
      end
  
      def perform_checks(specs, checks)
        checks.each do |check|
          if msg = send(check, specs)
            return msg
          end
        end
        nil
      end
  
      def check_all_dependencies(to_check, all, missing = [])
        to_check.each do |spec|
          spec.runtime_dependencies.each do |dep|
            if dep.name.start_with?("#{Wagons.app_name}_") &&
            all.none? {|s| dep.matches_spec?(s) }
              missing << "#{spec.name} requires #{dep.name} #{dep.requirement}"
            end
          end
        end
  
        missing.join("\n").presence
      end
      
      def gem_declaration_regexp(name)
        /^.*gem\s+('|")#{name}('|").*$/
      end
          
      def wagonfile_edit(specs)
        content = File.read(wagonfile) rescue ""
  
        specs.each do |spec|
          content = yield spec, content
        end
        content.gsub!(/(\n\s*\n\s*)+/, "\n") # remove empty lines
  
        wagonfile_write(content.strip)
      end
      
      def wagonfile_write(content)
        File.open(wagonfile, 'w') do |f|
          f.puts content
        end
      end
      
      def setup_wagons(specs)
        require 'open4'
        
        env = Rails.env
        cmd = setup_command(specs)
        Rails.logger.info(cmd)
        
        Bundler.with_clean_env do
          ENV['RAILS_ENV'] = env
          execute_setup(cmd)
        end
      end
      
      def remove_wagons(specs)
        Wagons.all.reverse.each do |wagon|
          if specs.find {|spec| wagon.gem_name == spec.name }
            wagon.unload_seed
            wagon.revert
          end
        end
      end
          
      def setup_command(specs)
        wagons = specs.collect {|s| s.name.sub(/^#{Wagons.app_name}_/, '') }.join(',')
        "cd #{Rails.root} && bundle exec rake wagon:setup WAGON=#{wagons} -t"
      end
      
      def execute_setup(cmd)
        msg = nil
        status = Open4.popen4(cmd) do |pid, input, output, errors|
          msg = errors.read
        end
        
        if status.exitstatus.to_i != 0
          raise msg.presence || "Unknown error while running wagon:setup"
        end
      end
      
      def change_internal(names, *checks)
        specs = specs_from_names(names)
        
        if msg = perform_checks(specs, checks)
          msg
        else
          yield specs
          nil
        end
      rescue Exception => e
        handle_exception(e, names)
      end
      
      def handle_exception(e, names)
        msg = e.message
        Rails.logger.error msg + "\n\t" + e.backtrace.join("\n\t")
        msg
      end
  
    end
  end
end