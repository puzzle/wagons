#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Here be Wagons'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

task :test => :bundle do
  begin
    in_dummy 'bundle exec rails g wagon test_wagon'
    in_dummy 'bundle exec rake wagon:bundle:update'
    in_dummy "bundle exec rake db:migrate test  #{'-t' if Rake.application.options.trace}"
    in_dummy "bundle exec rake wagon:test  #{'-t' if Rake.application.options.trace}"
  ensure
    sh 'rm -rf test/dummy/vendor/wagons/test_wagon'
  end
end

task :bundle => :set_rails_version do
  in_dummy 'rm -rf Gemfile.lock'
  if ENV['ROOT_BUNDLE_PATH'] # used by ci
    in_dummy 'mkdir -p .bundle'
    in_dummy 'echo "---\nBUNDLE_PATH: \"$ROOT_BUNDLE_PATH\"\n" > .bundle/config'
    in_dummy 'cat .bundle/config'
    in_dummy 'mkdir -p vendor/wagons/test_wagon/.bundle'
    in_dummy 'echo -e "---\nBUNDLE_PATH: \"$ROOT_BUNDLE_PATH\"\n" > vendor/wagons/test_wagon/.bundle/config'
    in_dummy 'mkdir -p vendor/wagons/superliner/.bundle'
    in_dummy 'echo -e "---\nBUNDLE_PATH: \"$ROOT_BUNDLE_PATH\"\n" > vendor/wagons/superliner/.bundle/config'
  end
  in_dummy 'bundle'
end

task :set_rails_version do
  if ENV['BUNDLE_GEMFILE']
    version = File.read(ENV['BUNDLE_GEMFILE'])[/gem\s*'rails',\s*'(.*)'/, 1]
    ENV['RAILS_VERSION'] = version
  end
end

task :default => :test

def in_dummy(command)
  version = "RAILS_VERSION=\"#{ENV['RAILS_VERSION']}\" " if ENV['RAILS_VERSION']
  Bundler.with_unbundled_env { sh "cd test/dummy && #{version}#{command}" }
end
