require 'test_helper'
require 'open3'
require 'fileutils'

# Integration test for the rake tasks of this gem.
#
# When rake runs inside a wagon directory, wagon_tasks.rake loads the
# application's Rakefile inside `namespace :app`, prefixing all
# application tasks with `app:`.
# Runtime task references in wagons.rake must therefore resolve relative
# to the namespace they were defined in, not the root scope.
class WagonTasksTest < ActiveSupport::TestCase
  DUMMY_DIR = File.expand_path('dummy', __dir__)
  WAGON_DIR = File.join(DUMMY_DIR, 'vendor', 'wagons', 'superliner')

  setup :install_bundles
  teardown :remove_wagon_lockfile, :remove_schema_file

  test 'app:db:migrate in wagon directory resolves db tasks inside the app namespace' do
    out, err, status = rake_in(WAGON_DIR, 'app:db:migrate --trace')
    assert status.success?, "app:db:migrate failed:\n#{out}#{err}"
    refute_match(/Don't know how to build task/, err)
    # prove that migrate invoked the app:-namespaced dump chain
    assert_match(/\*\* Invoke app:db:_dump_rails/, out + err)
    assert_match(/\*\* Invoke app:db:schema:dump/, out + err)
  end

  test 'app:db:_dump_rails in wagon directory resolves schema dump inside the app namespace' do
    out, err, status = rake_in(WAGON_DIR, 'app:db:_dump_rails --trace')
    assert status.success?, "app:db:_dump_rails failed:\n#{out}#{err}"
    assert_match(/\*\* Invoke app:db:schema:dump/, out + err)
  end

  test 'app:wagon:exec in wagon directory resolves exec task inside the app namespace' do
    out, err, status = rake_in(WAGON_DIR, 'app:wagon:exec', 'CMD' => 'echo wagon-exec-ok')
    assert status.success?, "app:wagon:exec failed:\n#{out}#{err}"
    assert_match(/wagon-exec-ok/, out)
  end

  test 'db:_dump_rails in the application directory resolves schema dump unprefixed' do
    out, err, status = rake_in(DUMMY_DIR, 'environment db:_dump_rails --trace')
    assert status.success?, "db:_dump_rails failed:\n#{out}#{err}"
    assert_match(/\*\* Invoke db:schema:dump/, out + err)
    refute_match(/\*\* Invoke app:/, out + err)
  end

  private

  def rake_in(dir, args, env = {})
    # SCHEMA redirects schema dumps to a tmp file so the committed
    # test/dummy/db/schema.rb is not touched; ignored by other tasks.
    env = {
      'RAILS_ENV' => 'test',
      'RAILS_VERSION' => Rails::VERSION::STRING,
      'SCHEMA' => schema_file
    }.merge(env)

    Bundler.with_unbundled_env do
      Dir.chdir(dir) do
        Open3.capture3(env, "bundle exec rake #{args}")
      end
    end
  end

  def install_bundles
    env = { 'RAILS_VERSION' => Rails::VERSION::STRING }
    [DUMMY_DIR, WAGON_DIR].each do |dir|
      Bundler.with_unbundled_env do
        Dir.chdir(dir) do
          next if system(env, 'bundle check', out: File::NULL, err: File::NULL)

          system(env, 'bundle install --local || bundle install') ||
            raise("could not install bundle in #{dir}")
        end
      end
    end
  end

  def remove_wagon_lockfile
    FileUtils.rm_f(File.join(WAGON_DIR, 'Gemfile.lock'))
  end

  def remove_schema_file
    FileUtils.rm_f(schema_file)
  end

  def schema_file
    @schema_file ||= begin
      dir = File.join(DUMMY_DIR, 'tmp')
      FileUtils.mkdir_p(dir)
      File.join(dir, 'wagon_tasks_test_schema.rb')
    end
  end
end
