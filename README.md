# FreshConnection

FreshConnection allows access to Mysql slave servers in Rails.

[![Gem Version](https://badge.fury.io/rb/fresh_connection.svg)](http://badge.fury.io/rb/fresh_connection) [![Build Status](https://travis-ci.org/tsukasaoishi/fresh_connection.svg?branch=master)](https://travis-ci.org/tsukasaoishi/fresh_connection) [![Code Climate](https://codeclimate.com/github/tsukasaoishi/fresh_connection/badges/gpa.svg)](https://codeclimate.com/github/tsukasaoishi/fresh_connection)

ActiveRecord can only access a single server by default.
FreshConnection can acccess to replicated Mysql slave servers via a loadbalancer,

For example.
```
Rails ------------ Mysql(Master)
             |
             |                     +------ Mysql(Slave1)
             |                     |
             +---- Loadbalancer ---+
                                   |
                                   +------ Mysql(Slave2)
```

When Rails controller's action begins, FreshConnction connects with one of slave servers behind the loadbalacer.
Read query goes to the slave server via the loadbalancer.
Write query goes to the master server. Inside transaction, all queries go to the master server.
All Mysql connections is disconnected at the end of the Rails controller's action.


## Usage

Read query goes to the slave server.

```ruby
Article.where(:id => 1)
```

If you want to access to the master saver, use readonly(false).

```ruby
Article.where(:id => 1).readonly(false)
```

In transaction, All queries go to the master server.

```ruby
Article.transaction do
  Article.where(:id => 1)
end
```

Create, Update. Delete queries go to the master server.

```ruby
article = Article.create(...)
article.title = "FreshConnection"
article.save
article.destory
```


## Installation

Add this line to your application's Gemfile:

    gem "fresh_connection"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fresh_connection


## Config
### config/database.yml

    production:
      adapter: mysql2
      encoding: utf8
      reconnect: true
      database: kaeru
      pool: 5
      username: master
      password: master
      host: localhost
      socket: /var/run/mysqld/mysqld.sock

      slave:
        username: slave
        password: slave
        host: slave

```slave``` is a config to connect to slave servers.
Others will use the master server setting.

### use multiple slave servers group
If you may want to use multiple slave groups, write the config to ```config/database.yml```.

    production:
      adapter: mysql2
      encoding: utf8
      reconnect: true
      database: kaeru
      pool: 5
      username: master
      password: master
      host: localhost
      socket: /var/run/mysqld/mysqld.sock

      slave:
        username: slave
        password: slave
        host: slave

      admin_slave:
        username: slave
        password: slave
        host: admin_slaves

And call the establish_fresh_connection method in a model that access to ```admin_slave``` slave group.

    class AdminUser < ActiveRecord::Base
      establish_fresh_connection :admin_slave
    end

The model of children class will access to same slave group as the parent.

    class Parent < ActiveRecord::Base
      establish_fresh_connection :admin_slave
    end

    class AdminUser < Parent
    end

    class Benefit < Parent
    end

AdminUser and Benefit access to ```admin_slave``` slave group.


### Declare model that doesn't use slave db

    class SomethingModel < ActiveRecord::Base
      master_db_only!
    end

If a model that always access to the master server is exist, You write ```master_db_only!```  in the model.
The model that master_db_only model's child is always access to master db.

### Slave Connection Manager
Default slave connection manager is FreshConnection::ConnectionManager.
If you would like to change slave connection manager, assign yourself slave connection manager.

#### config/application.rb

    config.fresh_connection.connection_manager = MySlaveConnection

or

#### config/initializers/fresh_connection.rb

    FreshConnection.connection_manager = MySlaveConnection


Yourself Slave Connection Manager should be inherited FreshConnection::AbstractConnectionManager

    class MySlaveConnection < FreshConnection::AbstractConnectionManager
      def slave_connection
        # must return object of ActiveRecord::ConnectionAdapters::Mysql2Adapter
      end

      def put_aside!
        # called when end of Rails controller action
      end

      def recovery(failure_connection, exception)
        # called when raise exception to access slave server
      end
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Test

I'm glad that you would do test!
To run the test suite, you need mysql installed.
How to setup your test environment.

First of all, you setting the config of the test mysql server in ```spec/database.yml```

```bash
bundle install --path bundle
GEM_HOME=bundle/ruby/(your ruby version) gem install bundler --pre
bundle exec appraisal install
```

This command run the spec suite for all rails versions supported.

```base
bundle exec appraisal rake spec
```

