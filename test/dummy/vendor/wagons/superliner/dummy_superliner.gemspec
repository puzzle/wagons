$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your wagon's version:
require 'dummy_superliner/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'dummy_superliner'
  s.version     = DummySuperliner::VERSION
  s.authors     = ['Your name']
  s.email       = ['Your email']
  # s.homepage    = "TODO"
  s.summary     = 'Superliner'
  s.description = 'Superliner description'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['Rakefile']
  s.test_files = Dir['test/**/*']

end
