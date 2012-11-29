require 'test_helper'

class PeopleControllerTest < ActionController::TestCase

  test "extensions are rendered with locals" do
    get :index
    assert_template 'index'
    assert_template 'list_superliner'
    assert_template 'sidebar'
    assert_template 'sidebar_superliner'
    assert_match /42/, @response.body
    assert_match /Superliner Details/, @response.body
    assert_no_match /Main Details/, @response.body
  end
  
end