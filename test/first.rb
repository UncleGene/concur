gem 'activerecord', '~> 3.0'
require 'active_record'
require 'minitest/autorun'
require 'logger'
 
ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'activerecord_unittest')
ActiveRecord::Base.logger = Logger.new(STDOUT)
 
ActiveRecord::Schema.define do
  drop_table :records if table_exists? :records
  create_table :records do |t|
    t.timestamps
  end
end
 
class Record < ActiveRecord::Base
end
 
class CuriousFirstTest < MiniTest::Unit::TestCase
  def test_first_last
    r = Record.create
    Record.create
    r.touch
    assert_equal 2, Record.count
    assert Record.first != Record.last, 'First of 2 records is also last!'
  end
end
