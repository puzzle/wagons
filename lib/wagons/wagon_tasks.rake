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


Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.title    = File.basename(ENGINE_PATH)
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('**/*.rdoc')
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks


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
    Wagons.current_wagon.migrate
  end

  desc "Revert the database (options: VERSION=x, VERBOSE=false)."
  task :revert => [:load_app, 'app:environment', 'app:db:load_config'] do
    Wagons.current_wagon.revert
  end

  desc "Load the seed data"
  task "seed" => [:load_app, 'app:db:abort_if_pending_migrations'] do
    Wagons.current_wagon.load_seed
  end

  desc "Unload the seed data"
  task "unseed" => [:load_app, 'app:db:abort_if_pending_migrations'] do
    Wagons.current_wagon.unload_seed
  end

  desc "Run migrations and seed data (use db:reset to also revert the db first)"
  task :setup => [:migrate, :seed]

  desc "Revert the database and set it up again"
  task :reset => [:unseed, :revert, :setup]

  desc "Display status of migrations"
  app_task "migrate:status"

  app_task "test:prepare"
end


Rake.application.invoke_task(:load_app)

task :notes => 'app:notes'

task :stats => ['wagon:statsetup', 'app:stats']

namespace :wagon do
  task :statsetup do
    load 'rails/tasks/statistics.rake' unless defined?(STATS_DIRECTORIES)
    require 'rails/code_statistics'
    STATS_DIRECTORIES.clear
    STATS_DIRECTORIES.concat([
        %w(Controllers app/controllers),
        %w(Helpers app/helpers),
        %w(Models app/models),
        %w(Mailers app/mailers),
        %w(Javascripts app/assets/javascripts),
        %w(Libraries lib/),
        %w(APIs app/apis),
        %w(Controller\ tests test/controllers),
        %w(Helper\ tests test/helpers),
        %w(Model\ tests test/models),
        %w(Mailer\ tests test/mailers),
        %w(Integration\ tests test/integration),
        %w(Functional\ tests\ (old) test/functional),
        %w(Unit\ tests\ (old) test/unit)
      ].collect { |name, dir| [ name, "#{ENGINE_PATH}/#{dir}" ] }.
        select { |name, dir| File.directory?(dir) })
  end
end


task :default => :test
