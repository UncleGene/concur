require_relative '../spec_helper'

describe MysqlSafeNumber do
  before :each do
    MysqlSafeNumber.delete_all
  end

  it 'should have unique values for find_or_create' do
    concurrently do
      50.times do 
        MysqlSafeNumber.first_or_create_where(value: MysqlSafeNumber.count)
      end
    end
    MysqlSafeNumber.count.must_equal MysqlSafeNumber.select('distinct value').count
  end

end
