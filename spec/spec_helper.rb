#ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'

class MiniTest::Spec
  def concurrently klass = ActiveRecord::Base, processes = 10, repeat = 20
    klass.remove_connection
    processes.times do
      fork do
        begin
          klass.establish_connection
          repeat.times do
            yield
          end
        ensure
          klass.remove_connection
        end
      end
    end
    Process.wait
    sleep 0.5 # wait a little more for db to process all requests ???
    klass.establish_connection
  end
end
