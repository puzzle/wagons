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
  task :unseed => :abort_if_pending_migrations do
    wagons.reverse.each { |wagon| wagon.unload_seed }
  end
  
  desc "Migrate and seed wagons"
  task :setup => [:migrate, :seed]
  
  desc "Remove the specified wagon"
  task :remove do
    if wagons.size != 1
      puts "Please specify a WAGON to remove"
    elsif message = wagons.first.protect?
      puts message
    else
      Rake::Task['wagon:unseed'].invoke
      Rake::Task['wagon:revert'].invoke
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
  
  desc "List the loaded wagons"
  task :list => :environment do  # depend on environment to get correct order
    wagons.each {|p| puts p.wagon_name }
  end
  
  desc "Run the tests of WAGON"
  task :test do
    ENV['CMD'] = 'bundle exec rake'
    Rake::Task['wagon:exec'].invoke
  end
  
  desc "Execute CMD in WAGON's base directory"
  task :exec do
    wagons.each do |w|
      puts "\n*** #{w.wagon_name.upcase} ***" if wagons.size > 1
      rel_dir = w.root.to_s.sub(Rails.root.to_s + File::SEPARATOR, '')
      with_clean_env do
        verbose(false) { sh "cd #{rel_dir} && #{ENV['CMD']}" }
      end
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
end


# Load the wagons specified by WAGON or all available.
def wagons
  to_load = ENV['WAGON'].blank? ? :all : ENV['WAGON'].split(",").map(&:strip)
  wagons = Wagon.all.select { |wagon| to_load == :all || to_load.include?(wagon.wagon_name) }
  puts "Please specify at least one valid WAGON" if ENV['WAGON'].present? && wagons.blank?
  wagons
end

BUNDLER_VARS = %w(BUNDLE_GEMFILE RUBYOPT BUNDLE_BIN_PATH)

# Bundler.with_clean_env does not work always. Probably better in v.1.1
def with_clean_env
  bundled_env = ENV.to_hash
  BUNDLER_VARS.each{ |var| ENV.delete(var) }
  yield
ensure
  ENV.replace(bundled_env.to_hash)
end 
