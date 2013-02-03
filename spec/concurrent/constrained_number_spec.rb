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
      ConstrainedNumber.create(:value => ConstrainedNumber.count)
    end

    ConstrainedNumber.count.must_equal ConstrainedNumber.select('distinct value').count
  end
end
