require 'test_helper'

class WagonTest < ActiveSupport::TestCase
  attr_reader :wagon
  def setup
    @wagon = Wagons.find(:superliner)
  end

  test 'all includes current wagon' do
    assert Wagons.all.include?(wagon)
  end

  test 'app name is correct' do
    assert_equal 'dummy', Wagons.app_name
  end

  test 'find for inexisting return nil' do
    assert_nil Wagons.find(:not_existing)
  end

  test 'version can be read from gemspec' do
    assert_equal Gem::Version.new('0.0.1'), wagon.version
  end

  test 'label can be read from gemspec' do
    assert_equal 'Superliner', wagon.label
  end

  test 'wagon_name does not have app prefix' do
    assert_equal 'superliner', wagon.wagon_name
  end

  test 'gem_name has app prefix' do
    assert_equal 'dummy_superliner', wagon.gem_name
  end

  test 'description can be read from gemspec' do
    assert_equal 'Superliner description', wagon.description
  end

  test 'dependencies is empty' do
    assert_equal [], wagon.dependencies
  end

  test 'all_dependencies is empty' do
    assert_equal [], wagon.all_dependencies
  end

  test 'existing seeds' do
    assert_equal({ City => City.where(:name => 'Paris') }, wagon.existing_seeds)
  end
end
