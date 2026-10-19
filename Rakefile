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
    in_dummy 'echo "---\nBUNDLE_PATH: \"${ROOT_BUNDLE_PATH}-dummy\"\n" > .bundle/config'
    in_dummy 'cat .bundle/config'
    in_dummy 'mkdir -p vendor/wagons/test_wagon/.bundle'
    in_dummy 'echo -e "---\nBUNDLE_PATH: \"${ROOT_BUNDLE_PATH}-dummy\"\n" > vendor/wagons/test_wagon/.bundle/config'
    in_dummy 'mkdir -p vendor/wagons/superliner/.bundle'
    in_dummy 'echo -e "---\nBUNDLE_PATH: \"${ROOT_BUNDLE_PATH}-dummy\"\n" > vendor/wagons/superliner/.bundle/config'
  end
  in_dummy 'bundle'
end

task :set_rails_version do
  rails = Gem.loaded_specs['rails']&.version
  ENV['RAILS_VERSION'] ||= rails.to_s if rails
end

namespace :test do
  desc 'Run the tests with the CI matrix (via mise), ' \
       'optionally filtered: test:matrix[ruby,gemfile]'
  task :matrix, [:ruby, :gemfile] do |_task, args|
    require 'yaml'
    matrix = YAML.load_file('.github/workflows/build.yml')
                 .dig('jobs', 'test', 'strategy', 'matrix')
    excludes = matrix.fetch('exclude', []).map { |e| e.values_at('ruby-version', 'gemfile') }
    all = matrix['ruby-version'].product(matrix['gemfile']) - excludes

    combos = all
    combos = combos.select { |r, _| r.include?(args[:ruby]) } unless args[:ruby].to_s.empty?
    combos = combos.select { |_, g| g.include?(args[:gemfile]) } unless args[:gemfile].to_s.empty?
    if combos.empty?
      abort "No matrix combination matches " \
            "ruby=#{args[:ruby].inspect}, gemfile=#{args[:gemfile].inspect}\n" \
            "Valid combinations:\n" +
            all.map { |r, g| "  [#{r},#{g}]" }.join("\n")
    end

    failures = combos.select do |ruby, gemfile|
      puts "\n#{'=' * 72}\nruby #{ruby} / #{gemfile}\n#{'=' * 72}"
      !Bundler.with_unbundled_env do
        system({ 'BUNDLE_GEMFILE' => gemfile },
               "mise exec ruby@#{ruby} -- sh -c 'bundle install --quiet && bundle exec rake'")
      end
    end

    if failures.any?
      abort "\nMatrix failed:\n" + failures.map { |r, g| "  ruby #{r} / #{g}" }.join("\n")
    end
  end
end

task :default => :test

def in_dummy(command)
  version = "RAILS_VERSION=\"#{ENV['RAILS_VERSION']}\" " if ENV['RAILS_VERSION']
  Bundler.with_unbundled_env { sh "cd test/dummy && #{version}#{command}" }
end
