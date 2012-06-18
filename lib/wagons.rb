require 'seed-fu-ndo'

require 'wagons/wagon'
require 'wagons/railtie'
require 'wagons/test_case'
require 'wagons/installer'
require 'wagons/version'

module Wagons
end

# Requires the specified argument but silently ignores any LoadErrors.
def optional_require(*args)
  require *args
rescue LoadError
  # that's fine, it's an optional require
end
