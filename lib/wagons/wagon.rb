# A wagon is an extension to your application train running on Rails.
# 
# Wagons are built on Rails Engines. To change an engine to a wagon,
# simply include this module into your own Engine.
module Wagon
  
  # All wagons installed in the current Rails application.
  def self.all
    Rails.application.railties.all.select {|r| r.is_a?(Wagon) }
  end
  
  # The name of the main Rails application.
  def self.app_name
    Rails.application.class.name.split('::').first.underscore
  end
  
  # Find a wagon by its name.
  def self.find(name)
    name = name.to_s
    all.find {|wagon| wagon.wagon_name == name || wagon.gem_name == name }
  end
  
  # Version from the gemspec.
  def version
    gemspec.version
  end
  
  # Human readable name.
  def label
    gemspec.summary
  end
  
  # Simple system name, without application prefix.
  def wagon_name
    gem_name.sub(/^#{Wagon.app_name}_/, '')
  end
  
  # Name of the gem.
  def gem_name
    class_name = self.class.name.demodulize.underscore
    engine_name.sub(/_#{class_name}$/, '')
  end
  
  # Description from the gemspec.
  def description
    gemspec.description
  end
  
  # Direct dependencies on other wagons.
  def dependencies
    gemspec.dependencies.collect(&:name).
                         select {|dep| dep =~ /\A#{Wagon.app_name}_/ }.
                         collect { |dep| Wagon.find(dep) || raise("No wagon #{dep} found") }
  end
  
  # Recursive depdencies on other wagons.
  def all_dependencies
    dependencies.collect {|dep| dep.all_dependencies + [dep] }.flatten.uniq
  end
  
  # Gem Specification.
  def gemspec
    Gem::Specification.find_by_name(gem_name)
  end
  
  # If true, this wagon may not be removed. Override as required.
  # May return a string with a message, why the wagon must not be removed.
  def protect?
    false
  end
  
  # Run the migrations.
  def migrate(version = nil)
    ActiveRecord::Migrator.migrate(migrations_paths, version)
  end
  
  # Revert the migrations.
  def revert
    ActiveRecord::Migrator.migrate(migrations_paths, 0)
  end
  
  # Load seed data in db/fixtures.
  def load_seed
    SeedFu.seed seed_fixtures
  end
  
  # Unload seed data in db/fixtures.
  def unload_seed
    SeedFuNdo.unseed seed_fixtures
  end
  
  def existing_seeds
    SeedFuNdo.existing_seeds seed_fixtures
  end
  
  # Paths for migration files.
  def migrations_paths
    paths['db/migrate'].existent
  end
  
  # Loads tasks into the main Rails application.
  # Overwritten to only load own rake tasks, without install:migrations task from Rails::Engine
  def load_tasks(app=self)
    railties.all { |r| r.load_tasks(app) }
    extend Rake::DSL if defined? Rake::DSL
    self.class.rake_tasks.each { |block| self.instance_exec(app, &block) }
    paths["lib/tasks"].existent.sort.each { |ext| load(ext) }
  end
  
  private
  
  def seed_fixtures
    fixtures = root.join('db', 'fixtures')
    ENV['NO_ENV'] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
  end
end

