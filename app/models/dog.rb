class Dog < ActiveRecord::Base
  has_one :head
  has_many :legs
end

class Head < ActiveRecord::Base
  belongs_to :dog
end

class Leg < ActiveRecord::Base
  belongs_to :dog
end
