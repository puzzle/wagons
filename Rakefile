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

task :test do
  with_clean_env { sh "cd test/dummy && bundle exec rake wagon:test  #{'-t' if Rake.application.options.trace}" }
end

task :default => :test


# Bundler.with_clean_env does not work always. Probably better in v.1.1
BUNDLER_VARS = %w(BUNDLE_GEMFILE RUBYOPT BUNDLE_BIN_PATH)
def with_clean_env
  bundled_env = ENV.to_hash
  BUNDLER_VARS.each{ |var| ENV.delete(var) }
  yield
ensure
  ENV.replace(bundled_env.to_hash)
end 
