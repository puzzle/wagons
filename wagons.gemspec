$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'wagons/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'wagons'
  s.version     = Wagons::VERSION
  s.authors     = ['Pascal Zumkehr']
  s.email       = ['spam@codez.ch']
  s.homepage    = 'http://github.com/puzzle/wagons'
  s.summary     = 'Wagons are extensions to your application train running on Rails.'
  s.description = 'Wagons are plugins that extend your specific Rails application. This framework makes it easy to create and manage them.'

  s.files = Dir['lib/**/{*,.[a-z]*}'] + ['MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'bundler', '>= 2.0'

  s.add_dependency 'rails', '>= 6.1'

  s.add_dependency 'seed-fu-ndo', '>= 0.0.3'

  s.add_dependency 'concurrent-ruby', '< 1.3.5'

  s.add_development_dependency 'open4'
  s.add_development_dependency 'sqlite3', '<= 2.1'
end
