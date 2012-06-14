Wagon.app_version = '1.0.0'

Wagon.all.each do |wagon|
  unless wagon.app_requirement.satisfied_by?(Wagon.app_version)
    raise "#{wagon.gem_name} requires application version #{wagon.app_requirement}; got #{Wagon.app_version}"
  end
end
