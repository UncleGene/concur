require_relative '../spec_helper'

describe SafeNumber do
  before :each do
    SafeNumber.delete_all
  end

  it 'should have unique values for find_or_create' do
    concurrently do
      SafeNumber.find_or_create(SafeNumber.count).new_record?.wont_equal true #Find better construct?
    end
    SafeNumber.count.must_equal SafeNumber.select('distinct value').count
  end

  it 'should have unique values for safe_create' do
    concurrently do
      SafeNumber.safe_create(:value => SafeNumber.count).new_record?.wont_equal true
    end
    SafeNumber.count.must_equal SafeNumber.select('distinct value').count
  end

  it 'should have unique values for safe_find_or_create' do
    concurrently do
      SafeNumber.safe_find_or_create(:value => SafeNumber.count).new_record?.wont_equal true
    end
    SafeNumber.count.must_equal SafeNumber.select('distinct value').count
  end

end
