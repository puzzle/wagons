# Configure Rails Environment
require File.expand_path('../../app_root', __FILE__)
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require File.expand_path('test/test_helper.rb', ENV['APP_ROOT'])


class ActiveSupport::TestCase  
  self.reset_fixture_path File.expand_path("../fixtures", __FILE__)
end
