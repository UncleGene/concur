require 'spec_helper'

describe ValidatedNumber do
  after :each do
    ValidatedNumber.delete_all
  end

  it 'should have unique valies' do
    concurrently do
      ValidatedNumber.create(:value => ValidatedNumber.count)
    end

    ValidatedNumber.count.must_equal ValidatedNumber.select('distinct value').count
  end
end
