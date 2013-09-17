Opening

----

Please raise your hand if you agree that you should not care about concurrency if

* you use rails?
* you use rails and ypu do not use multi-threading?
* rails, single thread, and low traffic?

Do you actively take precautions against concurrency issues?

----

Here is an example. This is Seattle Monorail. Mono means single - 
you can see this as a single-threaded Rails application.
And it is pretty low-traffic - two processes (trains) were enough. 

----

And everything can run fine for a long time - until it is not. 
Such applications are still subject to concurrency problems, and 
sometimes pretty bad one. Now in Seattle we are using a single process
to avoid concurrency issues.

----

Let look at when concurrency may become an issue

----

When we develop our application, we use an environment where we always have
[at most] one rails instance. We have absolutely no chance to encounter any concurrency
issues when we run our rails server, rails console or test suite.

(BTW, everywhere in this talk I assume you use classic relational Rails stack.
If you use NoSQL, you probably just exchange one set of problems to another)

But as soon as we deploy our application to production environment  ...

----

We are starting to be exposed to the first aspect of concurrency

- you have multiple Rails instances trying to talk to the same database
  (BTW, in this talk I assume you use classic relational Rails stack.
  If you use NoSQL, you probably just exchange one set of problems to another)
- and as soon as we start to scale, we have
- the aspect of unpredictable routing
  - you never know which host will reply to the request
  - or even in what order your hosts will reply

----

We'll start with looking at concurrency issues specific to Rails

----

But let at first invest in a tool set that would allow to reproduce such issues 
and verify our attempts to fix them.

- First of all, we need to make sure that we use in test the same database engine
and adaptor as anywhere else. Default sqlite is useless for our purposes.
But please, PLEASE, make sure that the database name is different!
- second - we just need to add to our code a helper function that will simulate
the multi-process environment
  - we fork provided block of code to multiple processes
  - and make sure at the end that all processes succeed

----

In reality this is a little bit more involved. As we are testing for concurrency, we
need to handle all shared resources safely ourselves.

- we need to make sure that each of our processes has its own database connection
(fork creates an exact copy, so without this all processes will try to se the same connection)
- and we need to take care of another shared resource - IO.
Without this precaution all processes can try to output everything at once,
and good luck in trying to parse interleaved exception backtraces.

----

Now we are ready to start digging. Our first facet is One and Only - you do not want users in your model  to
share the same social, or cars to have the same VIN (unless you are working on a counterfeit application)?

Rails gives us at least two ways to do this.

And the first of them is...

----

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

----

so - you have to change your code first to avoid such problems

----

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

----

The second tool Rails gives us - uniquiness validation

- We'll use another model that validates the value for uniquiness
- run practically the same test
- and get 59 non-unique values
- because underneath we do exactly the same,
  - just slightly different form of the query

----

and we get what we get!

----

The way to fix this is to do validation at the only place that knows about all your processes -
on database level.

- The most universal way to do this is to add an
  - unique index on the column.

    Unfortunately this is not enough - if you do not change your application code, 

- what you get ia a bunch of exceptions;
- this is the case where you can start appreciating that we "abbreviated" errors  in our
helper method.

----

We need to solve this problem ourselves...

----

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

----

We thought we straightened everything up, but..

----

Here is our MySQL-specific wrapper
- We have a second rescue block in our method
- Where we have to look inside the message to see whether to retry or rethrow the exception (as our statement may
  really be invalid)
- Finally we get this working!

----

Hurray! We are moving forward!

----

The second facet we are going to look at is associated with associations

----

To look at it let create a very practical and useful example.

- We'll try to build some dogs. Each of them will have one head and many legs. Sorry, Rails does not have has_four.
  Perhaps it has some reasons.
- And we'll have corresponding models for heads and legs

----

And now - let build some dogs.

- At first we'll create 20 dogs (sorry, no heads or legs)
- We'll find a dog without a head, and fix this problem
- We'll do the same to help the dog move around

----

To verify what we get I used a helper method pretty_report that just constructs a human-readable description, and
  we compare it with the expected result. What is your guess for how many combinations we will get?

- Out of 20 dogs we got only one normal, and 15 different types of monsters.

----

If you look carefully, the normal one managed to escape this accident

----

What happens with heads?

- let use our handy inspection tool. We can see here not 1, but 4 problems:
  - First - new head is always added to a dog, By this Rails practically guarantees
    that in cases when you substitute has_one association, there is a period of time
    where has_one constraint is violated - you guaranteed to have 2 associations.
  - Second - what we already saw in uniquiness, select happening before update
  - Third - Rails believes that we had at most one association before
  - And fourth (hope you can see tiny highlight) is what is not there. This statement
    does not ask for any order. No database that I am aware of guarantees **any** order
    unless explicitly asked. It means that when DB decides to change the order - this
    detection of "if there was anything before" fails.

----

Hello multi-headed monsters!

----

Let look at what happens with legs

- When dog does not have any legs, all new legs are getting attached 
- If it had some before, rails first detaches ones that it does not need, and
  attaches only necessary new ones (skipping already attached)
- But we still have the same basic problem - select before update

----

that leads us to the similar problem

----

Simplest way is to use what we already know.

- As we have only one head, we can use the same approach as we used with uniquiness.
  If we really want, we can do it for legs too, making our dog have one front left leg, one front right, etc.

----

But we may want to look at more universal solution. We are going to use database again.

- We will use database-level locking to prevent processes clashing into each other.
  - for this we will start transaction and lock the record right after finding it. Note that we are locking the
    "parent" record, even though we are not going to update it.
- We run our tests and can see that solution works. But we already saw that behavior can be database-specific.
- This time - you enjoy it only with MySQL. Postgres uses its right to return arbitrary record,
  and we still have problem with heads.

----

Rails 4 fixed the implicit ordering problem, but for Postgres on with other versions we need to keep looking

----



----

As we probably do not want to use this sledgehammer, let fix it ourselves.

- We are going to do a cleanup **after** update
  - For this we will do decapitation and amputation manually at the end
  - The key part here is that all processes have to agree what to remove.
    They should not be greedy and try to preserve what they just have added.
- And tests confirm for us that the cleanup approach succeeds

----

Facet 3: Emigration

----

When we do our database migrations,

- we are fine with adding tables
- adding columns and changing indices may cause locking problems (depending on database and how exactly you do it),
  but at least won't kill you
- but beware of column deletion.
  - if you are < 4.0

----

If we try to remove (unused!) column while our application is running

- Either with migration or directly from database
- We will start to see a lot of errors
  - because Rails still thinks that this column exists.

----

The worst part is that Rails will prevent your application from crashing, so this error will be there until your next
manual restart

----

If we look at what is happening under the hood

- Rails memoizes what columns your tables have, and never tries to refresh them.
- The good side is that all operations are using this method - so we can 'inject' behavior we need easily
- And it works for all Rails versions. Almost.
  - Notice the gap.

----

For fixing this we need to override this method in a model that have to loose the column

- The model will just pretend that it does not have it
- After updating your application and restarting
- We can safely remove the column,
- And remove this "hiding" code
- As with any pure cleanup, you are not forced to do deployment immediately

----

There should be some other way to do it for 3.1, but here is the answer I got on
StackOverflow. Let try to follow what it says:

Points 1 and 2 you need to do anyway, let start with 3:

* Start up a new database that is a master-master to your existing database
* Stop replication from your new database
* Drop your columns on the new database server
* One at a time reconfigure each application server to use the new database server and restart
* Turn replication back on for your new database
* Once the original server has caught back up, reconfigure the application to use that database server again (with
  applicable restarts)
* Stop replication and turn off new database server.

----

Woof...

----

Let talk about asset pipeline

----

To understand what can go wrong we need to look at how do we deploy our changes to servers.
One of valid methods of deployment is to

- shut down 
- all your servers
- replace your application
- and start up again

This is a very safe approach, but safety has its cost - and this cost is availability. You just took your site down
for unknown time.

----

If you don't want to give away your availability, you have to go with rolling deployment. The most common way to do this
is to:

- deploy your new code to a single host
- restart the server to pick up changes
- deploy to the next one…
  
  but here is a problem. Each rails deployment has only one version of assets.

In this state (before restart) server is still serving red pages, but it already managed to
"forget" about all red assets - so clients are getting un-styled pages with no javascript.
The way to mitigate this problem is to use a mix of two strategies.

----

We are going to

- shut down the first host
- update application and start it
  
We are fine on this host, here is the second problem (with any rolling deployment) - unpredictable routing.
You never know which host assets for your page are served from.
Pages served from the red host can try to get assets from the green one, and vice versa.

----

Fortunately Rails has almost all necessary pieces to avoid this problem (and give you a lot of additional benefits),
we just need to connect all dots together.

- We need to move our assets to a CDN
- If we use S3 for hosting assets, we can use 'asset_sync' gem that integrates asset uploading with asset compilation
- But in any case making sure all assets are uploaded to an asset host is not a rocket science
- We have to make sure that old assets are available for a time sufficient to finish deployment to all hosts (or even
  longer, in case you may need to roll back your changes)
- Just make sure that different versions of assets do not override each other

----

And we are rolling fast

----

This concludes our Rail-specific part. Remaining question is why resolution of such issues is left to developers?

- Rails goes out of its way to make simple tasks even simpler. It does this by adding a lot of magic tricks that hide
  what is going on behind the curtain.
- Unfortunately such hiding may (and will) strike back when your scenario even slightly deviate from the mainstream.
  (and what is mainstream is defined by rails core team). Looks like concurrency is not considered to
  be a problem common enough.

----

And now, finally, we are up to more interesting and not Rails-only stuff

----

The problem we we are going to look at is a problem of incremental functionality change

- Long ago ex - US Secretary of Defence described development and deployment as hardly combinable. Almost 30 years later
we all moved to this counterproductive environment as our everyday lifestyle. We are constantly developing and deploying
concurrently.

----

Here we see already familiar picture of our rolling deployment in the flight.

- To show what can and will happen I'll need some help

Two of you will be servers, other two - clients, and I'll be a router. Dear servers, please do not answer ny requests
until I route it to you!

- Server One: You have a simple API: on request "What do you have?" you are going to respond: "I have a candy in my
  left pocket".

  Please put it there. And on request "Please give me a candy from your left pocket" you'll share what you have. Please
  do not be greedy!

- Client one: please ask the server "What do you have?"  
- Dear server, please answer [I have a candy in my left pocket]
- For now, client one, you are distracted by what is going around, so please hold on your second request (I hope you can
  survive couple minutes without a candy?)
- Server Two, you are my new improved version. Your drastic improvement is that you have a candy in your right pocket.
- Client Two, please ask "What do ypu have?"
- Server Two, please answer [I have a candy in my right pocket]
- Client Two, please ask for your candy. You remember where it is? 
- I am routing this to you, Server One. Please give him a candy from your right pocket… What, you do not have it there?
  Please show us your interpretive dance for "Page not found"
- OK, Client One, time to wake up. You remember what to ask? [Please give me a candy from your left pocket]
- Server Two, as ypu are an improved version, ypu just crash on this request. Please show us "Server Down"

----

Now let fix this issue

- Server One, your API does not change, but I am giving yo a candy to put in your right pocket
- Server Two, here is one for your left pocket
- Now I can successfully deploy you, even if Server One is still around
- We need to wait some time till all potential requests are satisfied (please, give one of your candies to the clients
  each). Remember, that we need to wait all the time necessary for all clients to be satisfied
  (or you define what is "too late" and accept the fact that you have no chance to satisfy 100%)
- Now ypu can cleanup your backwards-compatibility code. For us cleanup means that I thank you for your help!

  - You should always treat your web server as an API provider
  - In software-as-a-service world, nobody would even imagine dropping a new
  API version without sufficient grace period, but web application developers do this all over the places.

----

So, returning to our starting quiz,

- you should not worry about the concurrency only if you do not care (BTW, "do not care"" is not necessarily negligence.
  Sometimes nature of your application may make you ether safe from such problems, or potential impact of concurrency
  issues is very limited)
- But if you do, remembering all potential sources of concurrency problems will help you to find a solution.

----

One way or another...

----

This exercise can help you to train your "concurrent" thinking

- Design an application that can help prepare slides for a talk
  - User can add a ToDo item in arbitrary place
  - User can easily move slides (or even move groups of slides) around
  - There should not be explicit "save"
- Focus on what is send over the network and what is persisted in your database. You get your points for considering:
  - Blocking vs. non-blocking saves
  - Some messages about user moving slides around can be lost
  - Or just come out-of-order
  - User can have your application opened in a different browser tab (or even on different computer) and can not notice
  that she sees several hours old copy.
  - Extra bonus - collaborative editing

Please feel free to use this question on your interviews, or even come with prepared answer to mine.

----

I'd like to (and in some cases have to) thank everybody who made this presentation possible

----

And now we are ready for Q&A session.
