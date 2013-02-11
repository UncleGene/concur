require 'spec_helper'

describe ValidatedNumber do
  after :each do
    ValidatedNumber.delete_all
  end

  it 'should have unique values' do
    concurrently do
      10.times{ ValidatedNumber.create(:value => ValidatedNumber.count) }
    end

    ValidatedNumber.count.must_equal ValidatedNumber.select(:value).uniq.count
  end
end
