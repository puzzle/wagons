require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  test "person without name is invalid" do
    person = Person.new
    assert !person.valid?
  end
  
  test "person has no idea about a city" do
    person = Person.new
    assert_raise(NoMethodError) do
      person.city_id = 42
    end
  end
  
  test "wagon models are not loaded in main application tests" do
    assert_raise(NameError) do
      City.new
    end
  end
end
