class Person < ActiveRecord::Base
  validates :name, presence: true
end
