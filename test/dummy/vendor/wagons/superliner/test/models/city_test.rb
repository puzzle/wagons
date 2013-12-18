require 'test_helper'

class CityTest < ActiveSupport::TestCase
  test "city without name is invalid" do
    city = City.new
    assert !city.valid?
  end
 
  test "fixtures from wagon are loaded" do
    assert_equal 'London', cities(:london).name
  end
end
