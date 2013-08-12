require 'spec_helper'

describe Dog do
  after :each do
    [Leg, Head, Dog].each(&:delete_all)
  end
  before :each do
    [Leg, Head, Dog].each(&:delete_all)
  end

  it 'dog should be normal' do
    200.times{ Dog.create }
    concurrently 20 do
      begin
        headless = Dog.includes(:head).reject(&:head).first
        if headless
          headless.create_head
          Head.update_all( { :dog_id => nil },
            { :id => Head.where(:dog_id => headless.id).order(:id).pluck(:id)[0..-2] })
        end
        legless = Dog.includes(:legs).select{|d| d.legs.empty?}.first
        if legless
          legless.legs = 4.times.map{ Leg.create }
          Leg.update_all( { :dog_id => nil },
            { :id => Leg.where(:dog_id => legless.id).order(:id).pluck(:id)[0..-5] })
        end
      end while headless || legless
    end

    Dog.all.group_by{ |dog| [ Head.where(:dog_id => dog.id).count, dog.legs.count ] }.
        map{ |k, v| [k[0], k[1], v.size] }.
        sort_by(&:last).
        reverse.
        map{ |(heads, legs, count)| "#{pz(count, 'dog')} with #{pz(heads, 'head')} and #{pz(legs, 'leg')}"}.
        join(', ').
        must_equal "200 dogs with 1 head and 4 legs"
  end

  def pz(n, str)
    "#{n} #{str}#{'s' if n != 1}"
  end
end
