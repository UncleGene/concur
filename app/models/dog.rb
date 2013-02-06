class Dog < ActiveRecord::Base
  has_one :head
  has_many :legs
end

class Head < ActiveRecord::Base
  belongs_to :dog
  scope :with_body, where('dog_id is not null')
end

class Leg < ActiveRecord::Base
  belongs_to :dog
end
