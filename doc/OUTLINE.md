# Rails vs Real Life

Rails is omakase. Important thing that restaurant owners forgot to include in the menu was a disclaimer:
"The consumption of raw or undercooked meats or eggs can be harmful to your health". We will look at some dishes
that are served raw by Rails and see how dangerous they can be. We will also try to find a way for you to finish
cooking these dishes yourself.

## Rails and Concurrency

More often than not I hear from new developers: "What concurrency? We are running Rails in single thread, so
there is no concurrency problems". Wrong. You do not need to think about concurrency only if you are creating a
toy application on a free Heroku plan (that allows only one process). As soon as you go to real world deployment, you
most probably have multiple Rails processes. And all these processes compete for a single resource - your database.

The first dish server raw on our menu - uniquiness

### Uniquiness

To be able to simulate multi-process environment in your tests, let add a simple method to [your favorite test
framework]. In this example we will be using MiniTest::Spec

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

#### find_or_create_by
One of simplest approaches (working perfectly in single process environment) is to force uniquiness by contract.
ActiveRecord method find_or_create_by_ does not produce duplicate records - it creates a new record only if one with
provided value is not found.

#### validates :uniquiness => true
#### DB constraints
#### Workaround
#### Migrations

## Security

### XSRF

## Raw Food From Guest Chefs - Database Migrations
