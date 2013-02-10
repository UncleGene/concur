ENV['RAILS_ENV'] ||= "test"
puts  "Starting in #{ENV['RAILS_ENV']} environment"
require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'

class MiniTest::Spec
  def concurrently processes = 10
    ActiveRecord::Base.remove_connection
    processes.times do
      fork do
        begin
          ActiveRecord::Base.establish_connection
          yield
        rescue => e
          puts "#{e.class.name}: #{e}"
          exit 1
        ensure
          ActiveRecord::Base.remove_connection
         end
      end
    end
    ActiveRecord::Base.establish_connection
    assert Process.waitall.map(&:last).all? &:success?
  end
end
