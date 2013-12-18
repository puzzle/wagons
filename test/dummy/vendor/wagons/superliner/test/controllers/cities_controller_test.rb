require 'test_helper'

class CitiesControllerTest < ActionController::TestCase

  test "wagon view paths preceed application view paths" do
    paths = @controller.view_paths.collect {|p| p }
    i_app = paths.index {|p| p.to_s.ends_with?('/dummy/app/views') }
    i_wagon = paths.index {|p| p.to_s.ends_with?('/superliner/app/views') }
    assert i_wagon < i_app
  end

end