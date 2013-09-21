class Dog < ActiveRecord::Base
  has_one :head
  has_many :legs

  class << self
    def all_str
      Dog.all.group_by { |dog| [Head.where(dog_id: dog.id).count, dog.legs.count] }.
        map { |k, v| [k[0], k[1], v.size] }.
        sort_by(&:last).
        reverse.
        map { |(heads, legs, count)| "#{pz(count, 'dog')} with #{pz(heads, 'head')} and #{pz(legs, 'leg')}" }.
        join(', ')
    end

    private
    # Simple pluralizer
    def pz(n, str)
      "#{n} #{str}#{'s' if n != 1}"
    end
  end
end

class Head < ActiveRecord::Base
  belongs_to :dog
end

class Leg < ActiveRecord::Base
  belongs_to :dog
end
