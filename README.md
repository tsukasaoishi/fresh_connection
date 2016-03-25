# FreshConnection
[![Gem Version](https://badge.fury.io/rb/fresh_connection.svg)](http://badge.fury.io/rb/fresh_connection) [![Build Status](https://travis-ci.org/tsukasaoishi/fresh_connection.svg?branch=master)](https://travis-ci.org/tsukasaoishi/fresh_connection) [![Code Climate](https://codeclimate.com/github/tsukasaoishi/fresh_connection/badges/gpa.svg)](https://codeclimate.com/github/tsukasaoishi/fresh_connection)

ActiveRecord accesses a single server by default.  
FreshConnection can access to slave servers via a load balancer.

For example.
```
Rails ------------ Master DB
             |
             |                     +------ Slave1 DB
             |                     |
             +---- Loadbalancer ---+
                                   |
                                   +------ Slave2 DB
```

FreshConnction connects with one of slave servers behind the load balancer.  
Read query goes to the slave server.  
Write query goes to the master server.  
Inside transaction, all queries go to the master server.  

If you can't use a load balancer, could use [EbisuConnection](https://github.com/tsukasaoishi/ebisu_connection).

## Usage
### Access to Slave
Read query goes to the slave server.

```ruby
Article.where(:id => 1)
```

### Access to Master
If read query want to access to the master server, use `read_master`.  
In before version 0.4.3, can use `readonly(false)`.

```ruby
Article.where(:id => 1).read_master
```

In transaction, All queries go to the master server.

```ruby
Article.transaction do
  Article.where(:id => 1)
end
```

Create, Update and Delete queries go to the master server.

```ruby
article = Article.create(...)
article.title = "FreshConnection"
article.save
article.destory
```

## Support Rails version
FreshConnection supports Rails version 4.0 or later.  
If you are using Rails 3.2, could use FreshConnection version 1.0.0 or before.

## Support DB
FreshConnection supports MySQL and PostgreSQL.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "fresh_connection"
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install fresh_connection
```


## Config
### config/database.yml

```yaml
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
```

```slave``` is a config to connect to slave servers.
Others will use the master server settings.

### use multiple slave servers group
If you may want to use multiple slave groups, write the config to ```config/database.yml```.

```yaml
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
```

And call the establish_fresh_connection method in a model that access to ```admin_slave``` slave group.

```ruby
class AdminUser < ActiveRecord::Base
  establish_fresh_connection :admin_slave
end
```

The children class will access to same slave group as the parent.

```ruby
class Parent < ActiveRecord::Base
  establish_fresh_connection :admin_slave
end

class AdminUser < Parent
end

class Benefit < Parent
end
```

AdminUser and Benefit access to ```admin_slave``` slave group.


### Declare model that doesn't use slave db

```ruby
class SomethingModel < ActiveRecord::Base
  master_db_only!
end
```

If a model that always access to the master server is exist, You write ```master_db_only!```  in the model.
The model that master_db_only model's child is always access to master db.

### for Unicorn

```ruby
before_fork do |server, worker|
  ...
  ActiveRecord::Base.clear_all_slave_connections!
  ...
end

after_fork do |server, worker|
  ...
  ActiveRecord::Base.establish_fresh_connection
  ...
end
```

### Slave Connection Manager
Default slave connection manager is FreshConnection::ConnectionManager.
If you would like to change slave connection manager, assign yourself slave connection manager.

#### config/initializers/fresh_connection.rb

```ruby
FreshConnection.connection_manager = MySlaveConnection
```


Yourself Slave Connection Manager should be inherited FreshConnection::AbstractConnectionManager

```ruby
class MySlaveConnection < FreshConnection::AbstractConnectionManager
  def slave_connection
    # must return object of ActiveRecord::ConnectionAdapters::Mysql2Adapter
  end

  def clear_all_connections!
    # called when all connections disconnect
  end
  
  def put_aside!
    # called when end of Rails controller action
  end

  def recovery?
    # called when raise exception to access slave server
    # retry to access when this method return true
  end
end
```


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
./bin/setup
```

This command run the spec suite for all rails versions supported.

```bash
./bin/test
```
