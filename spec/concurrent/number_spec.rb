require 'spec_helper'

describe Number do
  after :each do
    Number.delete_all
  end

  it 'should have unique valies' do
    concurrently do
      Number.find_or_create_by_value(Number.count)
    end

    Number.count.must_equal Number.select('distinct value').count
  end
end
