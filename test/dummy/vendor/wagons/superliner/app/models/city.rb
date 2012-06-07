class City < ActiveRecord::Base
  attr_accessible :name
  
  has_many :people
  
  validates :name, :presence => true
end
