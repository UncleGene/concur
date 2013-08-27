# Rails: Shadow Facets of Concurrency

Hello everybody!

My name is Eugene, and today we are going to talk about

## con·cur·ren·cy

Concurrency is so mysterious, that most online dictionaries do not even try to define it.

* Meriam-Webster at least gives you a tip where to look

* What is a little closer to home, wikipedia gives a CS-specific definition: 
  > concurrency is a property of systems in which several computations
are executing simultaneously, and potentially interacting with each other

* If we return back to Meriam-Webster, we can see that all synonyms have a positive tinge,
and antonyms are pretty negative.

What underlines the mystery of concurrency is that in Software Engineering we gradually
move the semantics of this word more and more toward its antonyms: when we say "concurrency",
in a lot of cases we mean concurrency issues or problems.

In this talk I am going to use concurrency almost solely in its inverted (or perverted?) meaning

But let start first with a short quiz

##  You may not worry about concurrency if

Please raise your hand if you agree that you should not care about concurrency if

* you use rails?
* you use MRI on rails?
* you use MRI on rails and/or you don't have a lot of visits?

I can assure you that at least somebody felt safe designing low-traffic single-threaded rails application -

* [pic] And reality stuck back!

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

- you have multiple Rails instancies trying to talk to the same database

- and as soon as we start to scale, we have

- the aspect of unpredictable routing

  - you never know which host will reply to the request

  - or even in what order your hosts will reply

## Part 1. Rails and Concurrency

We will start with looking at Rails-specific concurrency issues,
starting with shared resources, followed up by one routing aspect,
and will have a glance at more universal web application problems at the end

### RAILS_ENV=test

Just describing shared resource issues is too dry, and we want to be pragmatic in
our approach - so we need to invest in a mechanism that will allow us to demonstrate
the problem and to see if our mitigations work.

- First of all, we need to make sure that we use in test the same database engine
and adaptor as anywhere else. Default sqlite is useless for our purposes.
But please, PLEASE, make sure that the database name is different!
- second - we just need to add to our code a helper function that will simulate
the multi-process environment
  - we fork provided block of code to multiple processes
  - and make sure at the end that all processes succeed

### RAILS_ENV=test #2
In reality this is a little bit more involved. As we are testing for concurrency, we
need to handle all shared resources safely ourselves.

- we need to make sure that each of our processes has its own database connection
(fork creates an exact copy, so without this all processes will try to se the same connection)

- and we need to take care of another shared resource - IO.
Without this precaution all processes can try to output everything at once,
and good luck in trying to parse interleaved exception backtraces.

## Facet #1: One and Only

OK, now we are ready to start digging. Our first facet is One and Only -
how we can assure that no users in our model share the same social, or no cars have
the same VIN?

Rails gives us not even one, but two ways to do this.

And the first of them is 

### first_or_create

first_or_create (or its now deprecated twin find_or_create_by)

- To test this we'll create a simple model Number with a single attribute
conveniently called value.
- and to exercise this approach we have a simple test
  - that creates a number with a value corresponding to current database state.
    
    We want our test processes to collide as much as possible, and Number.count is used
as a simple synchronization mechanism

  - at the end we check that all values are unique by comparing number of records
with number of unique values

- Let run this test, and we see that 50 numbers (99 - 49) have non-unique values

- [pic] We got a some crooked rails!

### first_or_create.inspect
One of the best tools Rails provides to see what really happens is a query log
in Rails console

- Let see what happens. Rails really does what it says - first or create
  - It checks if record exists,
  - and creates a new one if it doesn't
  - second process comes in
  - finds the record and returns it.
- Everything works fine if these processes come one by one. But what can happen
if they come together?
  - First process: check!
  - Second process: check!
  - First process: I have to create!
  - Second: but I do too!
- [pic] and we get what we get!

### validates :uniquiness

The second tool Rails gives us - uniquiness validation

- We'll use another model that validates the value for uniquiness
- run practically the same test
- and get 59 non-unique values
- because underneath we do exactly the same,
  - just slightly different form of the query
- [pic] Oops.
 
  BTW, do not use first_or_create and validate uniquiness together. What you get
in this case is that for each record not found by first_or_create,
uniquiness validation will check again - and you have 2 database queries for the price
of non-working one.

### unique.fix :db

The way to fix this is to do validation at the only place that knows about all your processes -
on database level.

- The most universal way to do this is to add an
  - unique index on the column.

    Unfortunately this is not enough - if you do not change your application code, 

- what you get ia a bunch of exceptions;
- this is the case where you can start appreciating that we "abbreviated" errors  in our
helper method.
- [pic] so - you have to change your code first to avoid such problems

### unique.fix :db, diy: true

Instead of direct usage of first_or_create we'll need to

- wrap it in a custom method that handles RecordNotFound exception
  - by simply retrying the main flow.

Let run the test and make sure that everything is fine.

- And it is indeed.

  Or not...

  This works fine for Postgres. If we run the same code on MySQL

- we can get a nasty surprise. This surprise is a multi-layer one:
  - first, how MySQL manages to get to a deadlock performing
    the same operation? And second, why the adapter maps this to StatementInvalid exception -
    one that we can't blindly catch, as it can indicate real query problems.

- [pic] So our solution becomes not as elegant as before

### unique.fix :db, diy: true, mysql: true

- We have a second rescue block in our method
- Where we have to looks inside the message to see whether to retry or rethrow the exception
- Finally we get a hack that works fine on both Postgres and Mysql
- [pic] Hurray! We are moving forward!

## Facet #2: I Can Haz One or Many?

The second facet we are going to look at is ActiveRecord associations

### class Dog

To look at associations let create a very practicall example.

- We'll try to build some dogs. (why, or why Rails does not have has_four? Dog having many legs sounds very creepy. But, perhaps, it was concious choice…)
- And we'll have corresponding notion of a head and a leg

### Dog.build
And - let build some dogs.
- At first we'll create 20 dogs (sorry, no heads or legs)
- We'll find a dog without a head, and mitigate this problem
- We'll do the same to help the dog move around

### assert_sanity

To verify what we get I used a helper method pretty_report that constructs a string
of what interesting dogs can we get, and hopefully we can get 20 dogs with 1 head and 
4 legs each. Let run this test and see what we get

- Ouch… 3 dogs with 1 head and 8 legs, 1 dog with 2 heads and 32 legs, 1 dog with 2 heads and 40 legs…
- [pic] I'd rather have this collection of monsters not survive this rails accident

### dog.head.inspect
What heppens with heads?

- let use our handy inspection tool. We can see here not 1, but 4 problems:
  - First - new head is always added to a dog, By this Rails practically guarantees
    that in cases when you substitute has_one association, there is a period of time
    where has_one constraint is violated - you guaranteed to have 2 associations.
  - Second - what we already saw in uniquiness, select happening before update
  - Third - Rails believes that we had at most one association before
  - And fourth (hope you can see tiny highlight) is what is not there. This statement
    does not ask for any order. No database that I am aware of guarantees **any** order
    unless explicitely asked. It means that when DB decides to change the order - this
    detection of "if there was anything before" fails. 
  - [pic] Hello multi-headed dogs!    
    Side note - First 3 problems are shared (AFAIK) by all Rails version, but the 4th one
    is not a problem in 4.0, as it provides dafeult order to .first. Fix of 3.x is WIP
    
### dog.legs.inspect
Let look at what happens with legs

- When dog does not have any legs, all new legs are getting attached 
- If it had some before, rails first detaches ones that it does not need, and
  attaches only necessary new ones (skipping already attached)
- But we still have the same basic problem - select before update
  - [pic] that leads us to the same problem with concurrent updates
  
### dog.head.fix
- As we have only one head, we can use the same approach as we used with uniquiness.
  If we really want, we can reduce legs problem to uniquiness too by associating each leg (e.g. front left, front right, etc.) explicitly. But let try to find
more universal approach.

### dog.fix :db
- We will use database-level locking to prevent processes clashing into each other.
  - for this we will start transaction and lock the record right after finding it.
- Run your tests and enjoy your life…
- This time - you enjoy it only with MySQL. Postgres in this case still works firne with legs, but with head it apparently uses its right to return arbitrary record when asked for the first one
- [pic] You see this on Rails before 4.0 (and, hopefully, 3.2.15). Rails 4 finally 
  started to provide default order for .first
  
### dog.fix :db, force(:brute)
- We can try to use a lock together with finding the record we need to change
- And indeed, we have all our tests succeeding. But at what cost?
- If we look at our favorit inspection tool 
  - We can see that the whole table is locked!
  - This happens because model-level lock is applied to the scoped part our   
    statement. You'll need to train your eye to see where Arel ends and where Array 
    starts.
    
### dog.fix :diy
As we probably do not want to use the table lock sledgehammer, let fix it on
application level.
- We are going to do a cleanup **after** update ourselves
  - For this we will just 'detach' all extra heads and legs at the end
  - The key part here is that all processes have to agree what 'extra' means.
    They should not be greedy and try to preserve what they just have added.
- Tests confirm for us that the cleanup approach succeeds

## Facet #3: Emigration
### db:migrate
When we do our database migrations,  
- we are fine with adding tables
- or columns
- we are ok with adding or changing indices (with database-specific performance taxes)
- but beware of column deletion.
  - if you are < 4.0

### try :remove_column
- If we try to remove column on a "hot" website (making sure that nobody uses it)
- We will start to see a lot of errors
  - This column may not be used in your code, but Rails still uses it in a lot of queries. 
- [pic] The worst part is that your application level rescue will prevent your processes from failing completely, so this error will be there until your next restart

### remove_column.inspect
- This happens because rails memoizes what columns your tables have, and never tries to refresh this list
- It will help us to resolve the problem that all operations are using this method
- And it works for all Rails versions. Almost.
  - Notice the gap. 
    
    Rails 4 changed the game again, but at least it makes sure that inserts and updates do not fail in case of removed column [TODO: verify other operations]
    
### remove_column.fix

- For fixing this we need to override this method in a class that have to loose the column, to "hide" such column from the framework
- Update our application code and restart
- Now we can safely remove the column,
- Remove hiding code
- Do next restart, that may be much later, with some new feature launch.

### remove_column.fix :rails_3_1
There should be some other way to do it for 3.1, but here is the answer I got on
StackOverflow. Let try to follow what it says:

Points 1 and 2 you need to do anyway, let start with 3:

* Start up a new database that is a master-master to your existing database
* Stop replication from your new database
* Drop your columns on the new database server
* One at a time reconfigure each application server to use the new database server and restart
* Turn replication back on for your new database
* Omce the original server has caught back up, reconfigure the application to use that database server again (with applicable restarts)
* Stop replication and turn off new database server.
- [pic] Wow.

##Facet #4: Assets & Liabilities
Let talk about asset pipeline

### deploy :shutdown
To understand what can go wrong we need to look at how do we deploy our changes to servers.
One of valid methods of deployment is to 
- shut down 
- all your servers
- replace your application
- and start up again

This is a very safe approach, but safety has its cost - and this cost is availability. You just took your site down.

### deploy :rolling_swap
If you don't want to give away your availability, you have to go with rolling deployment. The most common way to do this is to

- deploy your new code to a single host
- restart the server to pick up changes
- deploy to the next one…
  
  but here is a problem. Each rails deployment has only one version of assets.
In this state (before restart) server is still serving red pages, but it already 
"forgot" about red assets - so clients are getting 404s, and you are getting routing errors. The way to mitigate this problem is to use a mix of two strategies.

### deploy :rolling_shutdown

We are going to

- shut down the first host
- update application and start it
  
  we are fine on this host, but here we have an issue with unpredictable routing.
Pages served from a red host can try to get assets from a green one, and vice versa.

### rake assets:fix

Fortunately Rails has almost all necessary pieces to avoid this problem, we just need to connect all dots together. 

- We need to enable asset host (and start using it!)
- If we use S3 for hosting assets, we can use 'asset_sync' gem that integrates asset uploading with asset compilation
- But in any case making sure all assets are uploaded to an asset host is not a rocket science
- We need to make sure that old assets are available for a time sufficient to finish deployment to all hosts (or even longer, in case you may need to roll back your changes)
- Just make sure that different versions of assets do not override each other  
- [pic] And we are fine again

## Rails.why?

- Rails goes out of its way to make simple tasks even simpler. It does this by adding a lot of magic tricks that hide what is going behind the curtain.
- Unfortunately such hiding may (and will) strike back when your scenario even slightly deviate froma the mainstream. Unfortunately it does not seem that concurrency issues made it to the mainstream yet.

# Part 2: Beyond Rails 

And now, finally, we are up to more interesting and not Rails-only stuff. The main difference is that if for Rails-specific issues you probably can find more-or-less universall workarounds, wider-scope concurrency problems usually do not have a silver bullet solution.

## Development and Deployment
- Lomg ago ex - US Secretary of Defence described development and deployment as hardly combineable. Almost 30 years later we all moved to this counterproductive environment as our everyday lifestyle. We are constantly developing and deploying concurrently.   

## Development and Deployment
Here we see already familiar picture of our rolling deployment in the flight.

- To show what can and will happen I'll need some help

Two of you will be servers, other two - clients, and I'll be a router. Dear servers, please do not answer ny requests untill I route it to you!

- Server One: You have a simple API: on request "What do you have?" you are going to respond: "I have a candy in my left pocket". Please put it there. And on request "Please give me a candy from your left pocket" you'll share what you have. Pelase do not be greedy!

- Client one: please ask the server "What do you have?"  

- Dear server, please answer [I have a candy in my left pocket]

- For now, client one, you are distracted by what is going around, so please hold on your second request (I hope you can sutvive couple minutes without a candy?)

- Server Two, you are my new improved version. Your drastic improvement is that you have a candy in your right pocket.

- Client Two, please ask "What do ypu have?"

- Server Two, please answer [I have a candy in my right pocket]

- Client Two, please ask for your candy. You remember where it is? 

- I am routing this to you, Server One. Please give him a candy from your right pocket… What, you do not have it there? Please show us your interpritive dance for "Page not found"

- OK, Client One, time to wake up. You remember what to ask? [Please give me a candy from your left pocket]

- Server Two, as ypu are an improved version, ypu just crash on this request. Please show us "Server Down"

- [pic]

## changed_feature.deploy!

Now let fix this issue

- Server One, your API does not change, but I am giving yo a candy to put in your right pocket
- Server Two, here is one for your left pocket
- Now I can successfully deploy you, even if Server One is still around
- We need to wait some time till all potential requests are satisfied (please, geive one of your candies to the clients each). Remember, that we need to wait all the time necessary for all clients to be satisfied (or you define what is "too late" and accept the fact that you have no chance to satisfy 100%)
- Now ypu can cleanup your backwards-compatibility code. For us cleanup means that I thank you for your help!

  - You should always treat your web server as an API provider
  - In software-as-a-service world, nobody would even imagine dropping a new
  API version without sufficient grace period, but web application developers do this all over the places. 
  
## You may not worry about concurrency if:

So, returning to our starting quiz,

- you should not worry about the concurrency only if you do not care (BTW, "do not care"" is not necessarily negligence. Sometimes nature of your application may make you ether safe from such problems, or potential impact of concurrency issues is very limited)
-  But if you do, remembering all potential sources of concurrency (shared resources and unpredictable routing, combined with non-atomic deployment process) will help you to find a solution.
-  [pic]

## Bonus: Homework

This excercise can help you to train your "cobncurrent" thinking

- Design a ToDo application, where
  - User can add a ToDo item in arbitrary place
  - App shoud support easy reordering of items
  - Everything is saved implicitely
- Focus on what is send over the network and what is persisted in your database. You get your points for considering:
  - Synchronous vs. asynchronous messaging
  - Some messages about user changing order of ToDo items can be lost
  - Some messages can come out-of-order
  - User can have your application opened in a different tabs (or even different computers)

Please feel free to use this question on your interviews, or even come with prepared answer to mine.  
  
## Credits

## Q & A

- .




  
   	
  













  
  