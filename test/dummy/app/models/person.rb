class Person < ActiveRecord::Base
  attr_accessible :birthday, :name
  
  validates :name, :presence => true
end
