# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dummy"
  s.version     = "0.0.0"
  s.authors     = ["Pascal Zumkehr"]
  s.email       = ["spam@codez.ch"]
  #s.homepage    = "TODO"
  s.summary     = "dummy application"
  s.description = "dummy application"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
  
  s.add_dependency 'wagons'
  s.add_dependency "sqlite3"
  
end