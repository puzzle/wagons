require 'seed-fu-ndo'

require 'wagons/wagon'
require 'wagons/railtie'
require 'wagons/installer'
require 'wagons/view_helper'
require 'wagons/version'

require 'wagons/extensions/application'
require 'wagons/extensions/require_optional'
require 'wagons/extensions/test_case'
if ::Rails::VERSION::STRING >= '4.1'
  require 'wagons/extensions/migration'
end

# Utility class to find single wagons and provide additional information
# about the main application.
module Wagons
  # All wagons installed in the current Rails application.
  def self.all
    enumerable = Rails.application.railties
    enumerable = enumerable.all if enumerable.respond_to?(:all)
    enumerable.select { |r| r.is_a?(Wagon) }
  end

  # Find a wagon by its name.
  def self.find(name)
    name = name.to_s
    all.find { |wagon| wagon.wagon_name == name || wagon.gem_name == name }
  end

  # The name of the main Rails application.
  # By default, this is the underscored name of the application module.
  # This name is directly used for the gem names,
  def self.app_name
    @app_name ||= Rails.application.class.name.split('::').first.underscore
  end

  # Set the application name. Should be lowercase with underscores.
  # Do this in an initializer.
  def self.app_name=(name)
    @app_name = name
  end

  # The version of the main application.
  def self.app_version
    @app_version ||= Gem::Version.new('0')
  end

  # Set the version of the main application.
  # Do this in an initializer.
  def self.app_version=(version)
    @app_version = version.is_a?(Gem::Version) ? version : Gem::Version.new(version)
  end

  # Returns the wagon that is currently executing a rake task or tests.
  def self.current_wagon
    @current_wagon ||= find_wagon(ENV['BUNDLE_GEMFILE'])
  end

  private

  def self.find_wagon(path)
    return if path.blank? || path == "/"

    wagon = Rails::Engine.find(path)
    return wagon if wagon
    find_wagon(File.expand_path('..', path))
  end
end
