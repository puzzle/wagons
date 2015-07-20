require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  test 'extensions are rendered with locals' do
    get :index
    assert_template 'index'
    assert_template '_list_superliner'
    assert_template '_list_main'
    assert_template '_sidebar'
    assert_template '_sidebar_superliner'
    assert_match /42/, @response.body
    assert_match /Superliner Details/, @response.body
    assert_match /List Superliner/, @response.body
    assert_no_match /List Main/, @response.body
    assert_no_match /List Superliner\s*List Superliner/m, @response.body
    assert_no_match /Main Details/, @response.body
  end
end
