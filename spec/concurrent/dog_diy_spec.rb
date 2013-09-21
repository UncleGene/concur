require 'spec_helper'

describe Dog do
  before :each do
    [Leg, Head, Dog].each(&:delete_all)
  end

  it 'dog should be normal' do
    50.times{ Dog.create }
    concurrently do
      begin
        headless = Dog.includes(:head).reject(&:head).first
        if headless
          headless.create_head
          Head.update_all({ dog_id: nil },
            { id: Head.where(dog_id: headless.id).order(:id).pluck(:id)[0..-2] })
        end
        legless = Dog.includes(:legs).select{|d| d.legs.empty?}.first
        if legless
          legless.legs = 4.times.map{ Leg.create }
          Leg.update_all({ dog_id: nil },
            { id: Leg.where(dog_id: legless.id).order(:id).pluck(:id)[0..-5] })
        end
      end while headless || legless
    end

    Dog.all_str.must_equal "50 dogs with 1 head and 4 legs"
  end
end
