module ActiveSupport #:nodoc:
  class TestCase
    # Resets the fixtures to the new path
    def self.reset_fixture_path(path)
      self.fixture_table_names = []
      self.fixture_class_names = {}
      if Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new('7.1.0')
        self.fixture_path = path
      else
        self.fixture_paths = [path]
      end
      fixtures :all
    end
  end
end
