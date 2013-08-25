# Rails: Shadow Facets of Concurrency

Hello everybody!

My name is Eugene (if you try to pronounce my last name, most of you will
sound as funny to me, as I'll do to you during this talk),
and today we are going to talk about &#9679;

## con·cur·ren·cy
... concurrency

Concurrency is so mysterious, that most online dictionaries do not even try to define it.

Meriam-Webster at least gives you a tip where to look &#9679;

What is a little closer to home, wikipedia gives a CS-specific definition: &#9679;

concurrency is a property of systems in which several computations
are executing simultaneously, and potentially interacting with each other

If we return back to Meriam-Webster &#9679;, we can see that all synonyms have a positive tinge,
and antonyms are pretty negative.

What underlines the mystery of concurrency is that in Software Engineering we gradually
move the semantics of this word more and more toward its antonyms: when we say "concurrency",
in a lot of cases we mean concurrency issues or problems.

In this talk I am going to use concurrency almost solely in its inverted (or perverted?) meaning

But let start first with a short quiz &#9679;

##  You may not worry about concurrency if

Please raise your hand if you agree that you should not care about concurrency if

&#9679; you use rails?

&#9679; you use MRI on rails?

&#9679; you use MRI on rails and/or you don't have a lot of visits?

I can assure you that at least somebody felt safe designing low-traffic single-threaded
rails application

&#9679; [pic] And reality stuck back!

## Why?

So, why and how concurrency impacts our already complex enough life?

### RAILS_ENV=development

When we develop our application, we use an environment where we always have
[at most] one rails instance. We have absolutely no chance to encounter any concurrency
issues when we run our rails server, rails console or test suite.

(BTW, everywhere in this talk I assume you use classic relational Rails stack.
If you use NoSQL, you probably just exchange one set of problems to another)

But as soon as we deploy our application to production environment

### RAILS_ENV=production

(assuming we do it the right way)

We are starting to be exposed to the first aspect of concurrency

&#9679; you have multiple Rails instancies trying to talk to the same database

&#9679; and as soon as we start to scale, we have

&#9679; the aspect of unpredictable routing

&#9679; you never know which host will reply to the request

&#9679; or even in what order your hosts will reply

## Part 1. Rails and Concurrency

We will start with looking at Rails-specific concurrency issues,
starting with shared resources, followed up by one routing aspect,
and will have a glance at more universal web application problems at the end

### RAILS_ENV=test

Just describing shared resource issues is too dry, and we want to be pragmatic in
our approach - so we need to invest in a mechanism that will allow us to demonstrate
the problem and to see if our mitigations work.

&#9679; First of all, we need to make sure that we use in test the same database engine
and adaptor as anywhere else. Default sqlite is useless for our purposes.
But please, PLEASE, make sure that the database name is different!

&#9679; second - we just need to add to our code a helper function that will simulate
the multi-process environment

&#9679; here we fork provided block of code to multiple processes

&#9679; and make sure at the end that all processes succeed

### RAILS_ENV=test #2
In reality this is a little bit more involved. As we are testing for concurrency, we
need to handle all shared resources safely ourselves.

&#9679; we need to make sure that each of our processes has its own database connection
(fork creates an exact copy, so without this all processes will try to se the same connection)

&#9679; and we need to take care of another shared resource, IO.
Without this precaution all processes can try to output everything at once,
and good luck in trying to parse interleaved exception backtraces.

## Facet #1: One and Only

OK, now we are ready to start digging. Our first facet is One and Only -
how we can assure that no users in our model share the same social, or no cars have
the same VIN?

Rails gives us not even one, but two ways to do this.

And the first of them is ...

### first_or_create

first_or_create (or its now deprecated twin find_or_create_by)

&#9679; To test this we'll create a simple model Number with a single attribute
conveniently called value.

&#9679; and to exercise this approach we have a simple test

&#9679; that creates a number with a value corresponding to current database state.

We want our test processes to collide as much as possible, and Number.count is used
as a simple synchronization mechanism

&#9679; at the end we check that all values are unique by comparing number of records
with number of unique values

Let run this test, and we see that 50 numbers (99 - 49) have non-unique values

&#9679; [pic] We got a some crooked rails!

### first_or_create.inspect

Let see what happens. Rails really does what it says - first or create

&#9679; It checks if record exists,

&#9679; and creates a new one if it doesn't

&#9679; second process comes in

&#9679; finds the record and returns it.

&#9679; Everything works fine if these processes come one by one. But what can happen
if they come together?

&#9679; First process: check!

&#9679; Second process: check!

&#9679; First process: I have to create!

&#9679; Second: but I do too!

&#9679; [pic] and we get what we get!

### validates :uniquiness

Let try the second tool Rails have - uniquiness validation

&#9679; We'll use another model that validates the value for uniquiness

&#9679; run practically the same test

&#9679; and get 59 non-unique values

&#9679; because underneath we do exactly the same,

&#9679; just slightly different form of the query

&#9679; [pic] Oops.

BTW, do not use first_or_create and validate uniquiness together. What you get
in this case is that for each record not found by first_or_create,
uniquiness validation will check again - and you have 2 database queries for the price
of non-working one.

### unique.fix :db

The way to fix this is to do validation at the only place that knows about all your processes -
on database level.

&#9679; The most universal way to do this is to add an

&#9679; unique index on the column.

Unfortunately this is not enough - if you do not change your application code, what you get

&#9679; ia a bunch of exceptions;

&#9679; this is the case where you can start appreciating that we "abbreviated" errors  in our
helper method.

&#9679; [pic] so - you have to change your code first to avoid such problems

### unique.fix :db, diy: true

Instead of direct usage of first_or_create we'll need to wrap it in a custom method that
handles RecordNotFound exception by simply retrying the main flow.

Let run the test and make sure that everything is fine. And it is indeed.

Or not...

This works fine for Postgres. If we run the same code on MySQL, we can get a nasty surprise.

&#9679;

This surprise is a multi-layer one: first, how MySQL manages to get to a deadlock performing
the same operation? And second, why the adapter maps this to StatementInvalid exception -
one that we can't blindly catch, as it can indicate real query problems.

&#9679; [pic]

So our solution becomes not as elegant as before

### unique.fix :db, diy: true, mysql: true

- We have a second rescue block in our method
- And it looks inside the message to see whether to retry or rethrow the exception
- Finally we get a hack that works fine on both Postgres and Mysql






