require 'spec_helper'

describe ConstrainedNumber do
  after :each do
    ConstrainedNumber.delete_all
  end
  before :each do
    ConstrainedNumber.delete_all
  end

  it 'should have unique values' do
    concurrently do
      10.times do 
        ConstrainedNumber.find_or_create_by_value(ConstrainedNumber.count)
      end
    end
    unique = ConstrainedNumber.select('distict value').count
    ConstrainedNumber.count.must_equal unique
  end

end
