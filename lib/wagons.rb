require 'seed-fu-ndo'

require 'wagons/wagon'
require 'wagons/railtie'
require 'wagons/test_case'

module Wagons
end

# Requires the specified argument but silently ignores an LoadErrors.
def optional_require(*args)
  require *args
rescue LoadError
  # that's fine, it's an optional require
end
