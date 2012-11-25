require 'test_helper'

class PeopleControllerTest < ActionController::TestCase

  test "extensions are rendered with locals" do
    get :index
    assert_template 'index'
    assert_template 'list_superliner'
    assert_template 'sidebar'
    assert_template 'sidebar_superliner'
    assert_match /42/, @response.body
  end
  
end