class ActiveSupport::TestCase
  
    # Resets the fixtures to the new path
    def self.reset_fixture_path(path)
        self.fixture_table_names = []
        self.fixture_class_names = {}
        self.fixture_path = path
        self.fixtures :all  
    end
end