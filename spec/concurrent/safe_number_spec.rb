require_relative '../spec_helper'

describe SafeNumber do
  before :each do
    SafeNumber.delete_all
  end

  it 'should have unique values for find_or_create' do
    concurrently 20 do
      50.times do 
        SafeNumber.find_or_create(SafeNumber.count)
      end
    end
    SafeNumber.count.must_equal SafeNumber.select('distinct value').count
  end

end
