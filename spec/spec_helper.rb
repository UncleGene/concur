ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'

class MiniTest::Spec
  def concurrently processes = 10, repeat = 20
    processes.times do
      fork do
        repeat.times do
          yield
        end
      end
    end
    Process.wait
  end
end
