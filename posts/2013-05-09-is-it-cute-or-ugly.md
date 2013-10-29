---
title: "Is it cute or ugly?"
created_at: 2013-05-09 13:07:49 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'refactoring', 'factory', 'dependency' ]
newsletter: :aar
---

Yesterday day I presented a small code snippet to my dear coworkers
(who I of course always respect) and (as usually) they were not impressed,
even though I liked my solution. So I wanted to know your opinion about
this little piece of code. Let's start with the beginning.

<!-- more -->

## Obvious way

The story is simple. You are writing code to communicate with external api. You are
thoughtful programmer so you don't store credentials in the code. You deploy to heroku
so obviously you keep things in `ENV`.

First thought:

```
#!ruby
class ApiProvider
  def initialize(login = nil, password = nil)
    login    ||= ENV['APIPROVIDER_LOGIN']
    password ||= ENV['APIPROVIDER_PASSWORD']
    @uri       = Addressable::URI.parse("http://api.example.org/query")
    @uri.query_values = {usr: login, pwd: password}
  end
end
```

My immediate concern: Why should the instance of my class know in its constructor about
the fact that we use `ENV` to store default `login` and `password` values. So perhaps we should
use some kind of factory that would create the object with provided values or the defaults ?

But in Ruby every class is a factory, so why not use is to our advantage...

## Introduce Factory

```
#!ruby

class ApiProvider
  def self.new(login = nil, password = nil)
    login    ||= ENV['APIPROVIDER_LOGIN']
    password ||= ENV['APIPROVIDER_PASSWORD']
    super(login, password)
  end

  def initialize(login, password)
    @uri = Addressable::URI.parse("http://api.example.org/query")
    @uri.query_values = {usr: login, pwd: password}
  end
end
```

There is still something wrong here, I think. Why would anyone want to provide login,
but not password ? Or password without login ? Doesn't make much sense to me.
So I decided to extract a new, little class.

## Extract class

```
#!ruby
class ApiProvider
  class Credentials < Struct.new(:login, :password)
  end
 
  def self.new(credentials = nil)
    credentials ||= Credentials.new( ENV['APIPROVIDER_LOGIN'], ENV['APIPROVIDER_PASSWORD'] )
    super(credentials)
  end
 
  def initialize(credentials)
    @uri = Addressable::URI.parse("http://api.example.org/query")
    @uri.query_values = {usr: credentials.login, pwd: credentials.password}
  end
end
```

Does it make sense here to use `Struct` ?
I think so, because `Credentials.new('l', 'p').should == Credentials.new('l', 'p')`.
But there are coworkers who disagree with me and I wonder what you think.

## Alternatives

* Default in method definition

```
#!ruby
class ApiProvider
  def self.new(credentials = Credentials.new( ENV['APIPROVIDER_LOGIN'], ENV['APIPROVIDER_PASSWORD'] ))
    super
  end
end

# or

class ApiProvider
  def initialize(credentials = Credentials.new( ENV['APIPROVIDER_LOGIN'], ENV['APIPROVIDER_PASSWORD'] ))
    @uri = Addressable::URI.parse("http://api.example.org/query")
    @uri.query_values = {usr: credentials.login, pwd: credentials.password}
  end
end
```

Somehow this seems to be less readable to me

* Moving the defaults to `Credentials`

```
#!ruby
class ApiProvider
  class Credentials < Struct.new(:login, :password)
    def self.default
      new( ENV['APIPROVIDER_LOGIN'], ENV['APIPROVIDER_PASSWORD'] )
    end
  end
 
  def initialize(credentials = Credentials.default)
    @uri = Addressable::URI.parse("http://api.example.org/query")
    @uri.query_values = {usr: credentials.login, pwd: credentials.password}
  end
end
```

Nice, but the knowledge about defaults was transffered from `ApiProvider.new` factory method
to `Credentials` and I believe that `Credentials` should but just a dumb class responsible only for
keeping `login` and `password` always together. Because in terms of this api it never makes sense
to operate separately on them.

* External context is always responsible for providing the configuration

```
#!ruby
api = ApiProvider.new( ENV['APIPROVIDER_LOGIN'], ENV['APIPROVIDER_PASSWORD'] )
api.do_something
```

This leads to repeated code if there are multiple places that need to instantiate `ApiProvider`.

## TLDR

* The constructor states that `ApiProvider` always requires `credentials`
as dependency for proper working

```
#!ruby
class ApiProvider
  def initialize(credentials)
    @uri = Addressable::URI.parse("http://api.example.org/query")
    @uri.query_values = {usr: credentials.login, pwd: credentials.password}
  end
end
```

* `ApiProvider.new` factory method is responsible for creating `ApiProvider` instance even without
explicit credentials because defaults can be used.

```
#!ruby
class ApiProvider
  def self.new(credentials = nil)
    credentials ||= Credentials.new( ENV['APIPROVIDER_LOGIN'], ENV['APIPROVIDER_PASSWORD'] )
    super(credentials)
  end
end
```

* `Credentials` is just a dumb struct for passing login and password together around the system

```
#!ruby
class Credentials < Struct.new(:login, :password)
end
```

Which way do you like the most ? Do you agree with me ? Or have I just
earned uncountable amount of haters ? Do you think that using `Struct` is a bad practice sometimes ?
