require 'test_helper'
require 'tmpdir'
require 'rails/generators'
require 'generators/wagon/wagon_generator'

class WagonGeneratorTest < ActiveSupport::TestCase
  attr_reader :app_dir, :templates_dir

  setup :create_dirs
  teardown :remove_dirs

  test 'copies template symlinks as symlinks' do
    File.symlink('../core/AGENTS.md', File.join(templates_dir, 'AGENTS.md'))
    File.write(File.join(templates_dir, 'target.txt'), 'content')
    File.symlink('target.txt', File.join(templates_dir, 'link.txt'))

    generate_wagon

    assert_equal '../core/AGENTS.md', File.readlink(wagon_file('AGENTS.md'))
    assert_equal 'target.txt', File.readlink(wagon_file('link.txt'))
    assert_equal 'content', File.read(wagon_file('target.txt'))
  end

  test 'copies directory symlinks as symlinks' do
    File.symlink('../core/.claude', File.join(templates_dir, '.claude'))
    FileUtils.mkdir(File.join(templates_dir, 'target_dir'))
    File.write(File.join(templates_dir, 'target_dir', 'file.txt'), 'content')
    File.symlink('target_dir', File.join(templates_dir, 'link_dir'))

    generate_wagon

    assert_equal '../core/.claude', File.readlink(wagon_file('.claude'))
    assert_equal 'target_dir', File.readlink(wagon_file('link_dir'))
    assert_equal 'content', File.read(wagon_file('target_dir/file.txt'))
  end

  test 'application template symlinks override files of the gem' do
    File.symlink('../core/app_root.rb', File.join(templates_dir, 'app_root.rb'))

    generate_wagon

    assert_equal '../core/app_root.rb', File.readlink(wagon_file('app_root.rb'))
  end

  private

  def generate_wagon
    generator = WagonGenerator.new(['foo'], {}, shell: Thor::Shell::Basic.new)
    generator.source_paths.unshift(templates_dir)
    generator.shell.mute { Dir.chdir(app_dir) { generator.invoke_all } }
  end

  def wagon_file(name)
    File.join(app_dir, 'vendor', 'wagons', 'foo', name)
  end

  def create_dirs
    @app_dir = Dir.mktmpdir
    @templates_dir = Dir.mktmpdir
  end

  def remove_dirs
    FileUtils.rm_rf([app_dir, templates_dir])
  end
end
