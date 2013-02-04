ENV['RAILS_ENV'] ||= "ptest"
puts  "Starting in #{ENV['RAILS_ENV']} environment"
require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'

class MiniTest::Spec
  def concurrently processes = 10, repeat = 20
    ActiveRecord::Base.remove_connection
    processes.times do
      fork do
        begin
          ActiveRecord::Base.establish_connection
          repeat.times do
            yield
          end
        ensure
          ActiveRecord::Base.remove_connection
        end
      end
    end
    Process.waitall
    ActiveRecord::Base.establish_connection
  end
end
