require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  test 'test seeds from application are loaded' do
    assert Person.where(name: 'Pascal').exists?
  end

  test 'person can live in a city' do
    person = Person.new(name: 'Fred')
    person.city = cities(:london)
    assert person.save
    assert cities(:london).people.include?(person)
  end
end
