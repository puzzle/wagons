# These are the tasks included by the specific wagons


begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake/testtask'

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end


Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
task :test => [:'app:db:test:prepare']

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.title    = File.basename(ENGINE_PATH)
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('**/*.rdoc')
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks


APP_RAKEFILE = File.join(ENV['APP_ROOT'], "Rakefile")

def app_task(name)
  task name => [:load_app, "app:db:#{name}"]
end

def find_engine_path(path)
  return if path == "/"

  if Rails::Engine.find(path)
    path
  else
    find_engine_path(File.expand_path('..', path))
  end
end

def wagon
  @wagon ||= Rails::Engine.find(ENGINE_PATH)
end

task "load_app" do
  namespace :app do
    load APP_RAKEFILE
  end
  task :environment => "app:environment"

  if !defined?(ENGINE_PATH) || !ENGINE_PATH
    ENGINE_PATH = find_engine_path(APP_RAKEFILE)
  end
end


namespace :db do
  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate => [:load_app, 'app:environment', 'app:db:load_config'] do
    wagon.migrate
  end
  
  desc "Revert the database (options: VERSION=x, VERBOSE=false)."
  task :revert => [:load_app, 'app:environment', 'app:db:load_config'] do
    wagon.revert
  end

  desc "Load the seed data"
  task "seed" => [:load_app, 'app:db:abort_if_pending_migrations'] do
    wagon.load_seed
  end

  desc "Unload the seed data"
  task "unseed" => [:load_app, 'app:db:abort_if_pending_migrations'] do
    wagon.unload_seed
  end
  
  desc "Run migrations and seed data (use db:reset to also revert the db first)"
  task :setup => [:migrate, :seed]
  
  desc "Revert the database and set it up again"
  task :reset => [:unseed, :revert, :setup]
  
  desc "Display status of migrations"
  app_task "migrate:status"
end


Rake.application.invoke_task(:load_app)


namespace :app do
  task :environment do
    # set migrations paths only to core to have db:test:prepare work as desired
    ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
  end
    
  namespace :db do
    namespace :test do
      # for sqlite, make sure to delete the test.sqlite3 from the main application
      task :purge do 
        abcs = ActiveRecord::Base.configurations
        case abcs['test']['adapter']
        when /sqlite/
          dbfile = Rails.application.root.join(abcs['test']['database'])
          File.delete(dbfile) if File.exist?(dbfile)
        end
      end
      
      # run wagon migrations and load seed data
      task :prepare do
        Rails.env = 'test'
        dependencies = (wagon.all_dependencies + [wagon])
        
        # migrate 
        dependencies.each { |d| d.migrate }
        
        # seed
        SeedFu.quiet = true unless ENV['VERBOSE']
        SeedFu.seed([ Rails.root.join('db/fixtures').to_s,
                      Rails.root.join('db/fixtures/test').to_s ])
        dependencies.each { |d| d.load_seed }
      end
    end
  end
end

def inherited_dependencies(all, gem_name)
  if gem = Bundler.load.specs.find {|s| s.name == gem_name}
    depts = gem.dependencies.collect(&:name)
    if gem_name == Wagon.app_name
      depts.reject! {|d| d =~ /^#{Wagon.app_name}_.+$/ }
    end
    unless all.include?(gem_name)
      all << gem_name
      depts.each {|d| inherited_dependencies(all, d) }
    end
  end
end

def delete_gem(name)
  gem = File.join('vendor', 'cache', "#{name}.gem")
  File.delete(gem) if File.exists?(gem)
end

namespace :bundle do
  task :package do
    rt = Bundler.load
    rt.cache
    
    wagons = wagon.gemspec.runtime_dependencies.collect(&:name).select {|d| d =~ /^#{Wagon.app_name}(_.+)?$/ }
    depts = []
    wagons.each {|d| inherited_dependencies(depts, d) }
    depts.collect! {|d| rt.specs.find {|s| s.name == d }.full_name }
    depts.each do |d|
      delete_gem(d)
    end
    
    gems = wagon.gemspec.runtime_dependencies.collect(&:name).select {|d| d !~ /^#{Wagon.app_name}(_.+)?$/ }
    depts = []
    gems.each {|d| inherited_dependencies(depts, d) }
    depts.collect! {|d| rt.specs.find {|s| s.name == d }.full_name }
    
    Dir.glob("vendor/cache/*.gem").each do |file|
      unless depts.include?(File.basename(file, '.gem'))
        File.delete(file)
      end
    end
  end
end



task :default => :test
