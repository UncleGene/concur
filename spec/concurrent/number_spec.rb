require 'spec_helper'

describe Number do
  after :each do
    Number.delete_all
  end
  before :each do
    Number.delete_all
  end

  it 'should have unique values' do
    concurrently do
      10.times{ Number.find_or_create_by_value(Number.count) }
    end
    
    0.must_equal Number.count - Number.select('distinct value').count, 'Not unique values'
  end
end
