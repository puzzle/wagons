# The tasks available to the base application using wagons.

namespace :wagon do
  desc "Run wagon migrations (options: VERSION=x, WAGON=abc, VERBOSE=false)"
  task :migrate => [:environment, :'db:load_config'] do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    wagons.each do |wagon|
      wagon.migrate(ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end
  end
  
  desc "Revert wagon migrations (options: WAGON=abc, VERBOSE=false)"
  task :revert => [:environment, :'db:load_config'] do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    wagons.reverse.each do |wagon|
      wagon.revert
    end
  end
  
  desc "Seed wagon data (options: WAGON=abc)"
  task :seed => :abort_if_pending_migrations do 
    wagons.each { |wagon| wagon.load_seed }
  end
  
  desc "Unseed wagon data (options: WAGON=abc)"
  task :unseed do
    wagons.reverse.each { |wagon| wagon.unload_seed }
  end
  
  desc "Migrate and seed wagons"
  task :setup => [:migrate, :seed]
  
  desc "Remove the specified wagon"
  task :remove => :environment do
    if wagons.size == 0 || (wagons.size > 1 && ENV['WAGON'].blank?)
      puts "Please specify a WAGON to remove, or WAGON=ALL to remove all"
    else
      messages = wagons.collect {|w| w.protect? }.compact
      if messages.present?
        fail messages.join("\n")
      else
        Rake::Task['wagon:unseed'].invoke
        Rake::Task['wagon:revert'].invoke
      end
    end
  end
  
  desc "Generate an initializer to set the application version"
  task :app_version do
    file = Rails.root.join('config', 'initializers', 'wagon_app_version.rb')
    unless File.exist?(file)
      File.open(file, 'w') do |f|
        f.puts <<FIN
Wagons.app_version = '1.0.0'

Wagons.all.each do |wagon|
  unless wagon.app_requirement.satisfied_by?(Wagons.app_version)
    raise "\#{wagon.gem_name} requires application version \#{wagon.app_requirement}; got \#{Wagons.app_version}"
  end
end
FIN
      end
    end
  end
  
  desc "Creates a Wagonfile for development"
  task :file do
    file = Rails.root.join('Wagonfile')
    unless File.exist?(file)
      File.open(file, 'w') do |f|
        f.puts <<FIN
group :development do
    # Load all wagons found in vendor/wagons/*
    Dir[File.expand_path('../vendor/wagons/**/*.gemspec', __FILE__)].each do |spec|
        gem File.basename(spec, '.gemspec'), :path => File.expand_path('..', spec)
    end
end
FIN
      end
    end
    gemfile = Rails.root.join('Gemfile')
    content = File.read(gemfile)
    unless content =~ /wagonfile/
      File.open(gemfile, 'w') do |f|
        f.puts content
        f.puts "\n\n"
        f.puts "# Include the wagon gems you want attached in Wagonfile. 
# Do not check Wagonfile into source control.
#
# To create a Wagonfile suitable for development, run 'rake wagon:file'
wagonfile = File.expand_path('../Wagonfile', __FILE__)
eval(File.read(wagonfile)) if File.exist?(wagonfile)"
      end
    end
  end
  
  namespace :file do
    desc "Create a Wagonfile for production"
    task :prod => :environment do
      file = Rails.root.join('Wagonfile.prod')
      File.open(file, 'w') do |f|
        Wagons.all.each do |w|
          f.puts "gem '#{w.gem_name}', '#{w.version}'"
        end
      end
    end
  end
  
  desc "List the loaded wagons"
  task :list => :environment do  # depend on environment to get correct order
    wagons.each {|p| puts p.wagon_name }
  end
  
  desc "Run the tests of WAGON"
  task :test do
    ENV['CMD'] = "bundle exec rake #{'-t' if Rake.application.options.trace}"
    Rake::Task['wagon:exec'].invoke
  end
  
  desc "Execute CMD in WAGON's base directory"
  task :exec do
    wagons.each do |w|
      puts "\n*** #{w.wagon_name.upcase} ***" if wagons.size > 1
      rel_dir = w.root.to_s.sub(Rails.root.to_s + File::SEPARATOR, '')
      cmd = "cd #{rel_dir} && #{ENV['CMD']}"
      Bundler.with_clean_env do
        verbose(Rake.application.options.trace) { sh cmd }
      end
    end
    Rake::Task['wagon:exec'].reenable
  end
  
  namespace :bundle do
    desc "Run bundle update for all WAGONs"
    task :update do
      ENV['CMD'] = "bundle update --local"
      Rake::Task['wagon:exec'].invoke
    end
  end
  
  
  # desc "Raises an error if there are pending wagon migrations"
  task :abort_if_pending_migrations => :environment do
    pending_migrations = ActiveRecord::Migrator.new(:up, wagons.collect(&:migrations_paths).flatten).pending_migrations

    if pending_migrations.any?
      puts "You have #{pending_migrations.size} pending migrations:"
      pending_migrations.each do |pending_migration|
        puts '  %4d %s' % [pending_migration.version, pending_migration.name]
      end
      abort %{Run `rake wagon:migrate` to update your database then try again.}
    end
  end
end

namespace :test do
  desc "Test wagons (option WAGON=abc)"
  task :wagons => 'wagon:test'
end


namespace :db do
    namespace :seed do
      desc "Load core and wagon seeds into the current environment's database."
      task :all => ['db:seed', 'wagon:seed']
    end
    
    namespace :setup do
      desc "Create the database, load the schema, initialize with the seed data for core and wagons"
      task :all => ['db:setup', 'wagon:setup']
    end
    
    namespace :reset do
      desc "Recreate the database, load the schema, initialize with the seed data for core and wagons"
      task :all => ['db:reset', 'wagon:setup']
    end
    
    # DB schema should not be dumped if wagon migrations are loaded
    Rake::Task[:'db:_dump'].clear_actions

    task :_dump do
      migrations = ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)
      migrated = Set.new(ActiveRecord::Migrator.get_all_versions)
      if migrated.size > migrations.size
        puts "The database schema will not be dumped when there are loaded wagon migrations."
        puts "To dump the application schema, please 'rake wagon:remove WAGON=ALL' wagons beforehand or reset the database."
      else
        Rake::Task[:'db:_dump_rails'].invoke
      end
      
      Rake::Task[:'db:_dump'].reenable
    end
    
    task :_dump_rails do
      case ActiveRecord::Base.schema_format
      when :ruby then Rake::Task["db:schema:dump"].invoke
      when :sql  then Rake::Task["db:structure:dump"].invoke
      else
        raise "unknown schema format #{ActiveRecord::Base.schema_format}"
      end
      Rake::Task[:'db:_dump_rails'].reenable
    end
end


# Load the wagons specified by WAGON or all available.
def wagons
  to_load = ENV['WAGON'].blank? || ENV['WAGON'] == 'ALL' ? :all : ENV['WAGON'].split(",").map(&:strip)
  wagons = Wagons.all.select { |wagon| to_load == :all || to_load.include?(wagon.wagon_name) }
  puts "Please specify at least one valid WAGON" if ENV['WAGON'].present? && wagons.blank?
  wagons
end

