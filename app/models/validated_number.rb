class ValidatedNumber < ActiveRecord::Base
  attr_accessible :value
  validates :value, :uniqueness => true
end
