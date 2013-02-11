require_relative '../spec_helper'

describe MysqlSafeNumber do
  before :each do
    MysqlSafeNumber.delete_all
  end

  it 'should have unique values for find_or_create' do
    concurrently 20 do
      50.times do 
        raise "Invalid record" if MysqlSafeNumber.find_or_create(MysqlSafeNumber.count).new_record?
      end
    end
    MysqlSafeNumber.count.must_equal MysqlSafeNumber.select(:value).uniq.count
  end

end
