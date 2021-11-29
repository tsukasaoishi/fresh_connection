# FreshConnection
[![Gem Version](https://badge.fury.io/rb/fresh_connection.svg)](http://badge.fury.io/rb/fresh_connection) [![Build Status](https://travis-ci.org/tsukasaoishi/fresh_connection.svg?branch=master)](https://travis-ci.org/tsukasaoishi/fresh_connection) [![Code Climate](https://codeclimate.com/github/tsukasaoishi/fresh_connection/badges/gpa.svg)](https://codeclimate.com/github/tsukasaoishi/fresh_connection)

**FreshConnection** provides access to one or more configured database replicas.

For example:

```text
Rails ------------ DB Master
             |
             +---- DB Replica
```

or

```text
Rails -------+---- DB Master
             |
             |                     +------ DB Replica1
             |                     |
             +---- Loadbalancer ---+
                                   |
                                   +------ DB Replica2
```

FreshConnction connects one or more configured DB replicas, or with multiple replicas behind a DB query load balancer.

- Read queries go to the DB replica.
- Write queries go to the DB master.
- Within a transaction, all queries go to the DB master.

### Failover
FreshConnection assumes that there is a load balancer in front of multi replica servers.  
When what happens one of the replicas is unreachable for any reason, FreshConnection will try three retries to access to a replica via a load balancer.  

Removing a trouble replica from a cluster is a work of the load balancer.  
FreshConnection expects the load balancer to work during three retries.  

If you would like access to multi replica servers without a load balancer, you should use [EbisuConnection](https://github.com/tsukasaoishi/ebisu_connection).  
EbisuConnection has functions of load balancer.

## Usage
### Access to the DB Replica
Read queries are automatically connected to the DB replica.

```ruby
Article.where(id: 1)

Account.count
```

### Access to the DB Master
If you wish to ensure that queries are directed to the DB master, call `read_master`.

```ruby
Article.where(id: 1).read_master

Account.read_master.count
```

Within transactions, all queries are connected to the DB master.

```ruby
Article.transaction do
  Article.where(id: 1)
end
```

Create, update and delete queries are connected to the DB master.

```ruby
new_article = Article.create(...)
new_article.title = "FreshConnection"
new_article.save
...
old_article.destroy
```

## ActiveRecord Versions Supported

- FreshConnection supports ActiveRecord version 5.2 or later.
- If you are using Rails 5.1, you can use FreshConnection version 3.0.3 or before.

### Not Support Multiple Database
I haven't tested it in an environment using MultipleDB in Rails 6.
I plan to enable use with MultipleDB in FreshConnection version 4.0 or later.

## Databases Supported
FreshConnection currently supports MySQL and PostgreSQL.

## Installation
Add this line to your application's `Gemfile`:

```ruby
gem "fresh_connection"
```

And then execute:

```
$ bundle
```

Or install it manually with:

```
$ gem install fresh_connection
```

## Configuration

The FreshConnection database replica is configured within the standard Rails
database configuration file, `config/database.yml`, using a `replica:` stanza.

Below is a sample such configuration file.

### `config/database.yml`

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password:

production:
  <<: *default
  database: blog_production
  username: master_db_user
  password: <%= ENV['MASTER_DATABASE_PASSWORD'] %>
  host: master_db

  replica:
    username: replica_db_user
    password: <%= ENV['REPLICA_DATABASE_PASSWORD'] %>
    host: replica_db
```

`replica` is the configuration used for connecting read-only queries to the database replica.  All other connections will use the database master settings.

**NOTE:** 
The 'replica' stanza has a special meaning in Rails6.  
In Rails6, use a name other than 'replica', and specify that name using establish_fresh_connection in ApplicationRecord etc.

### Multiple DB Replicas
If you want to use multiple configured DB replicas, the configuration can contain multiple `replica` stanzas in the configuration file `config/database.yml`.

For example:

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password:

production:
  <<: *default
  database: blog_production
  username: master_db_user
  password: <%= ENV['MASTER_DATABASE_PASSWORD'] %>
  host: master_db

  replica:
    username: replica_db_user
    password: <%= ENV['REPLICA_DATABASE_PASSWORD'] %>
    host: replica_db

  admin_replica:
    username: admin_replica_db_user
    password: <%= ENV['ADMIN_REPLICA_DATABASE_PASSWORD'] %>
    host: admin_replica_db
```

The custom replica stanza can then be applied as an argument to the `establish_fresh_connection` method in the models that should use it.  For example:

```ruby
class AdminUser < ActiveRecord::Base
  establish_fresh_connection :admin_replica
end
```

The child (sub) classes of the configured model will inherit the same access as the parent class.  Example:

```ruby
class AdminBase < ActiveRecord::Base
  establish_fresh_connection :admin_replica
end

class AdminUser < AdminBase
end

class Benefit < AdminBase
end

class Customer < ActiveRecord::Base
end
```

The `AdminUser` and `Benefit` models will access the database configured for the `admin_replica` group.

The `Customer` model will use the default connections: read-only queries will connect to the standard DB replica, and state-changing queries will connect to the DB master.


### Replica Configuration With Environment Variables

Alternative to using a configuration in the `database.yml` file, it is possible to completely specify the replica access components using environment variables.

The environment variables corresponding to the `:replica` group are `DATABASE_REPLICA_URL`.  
The URL string components is the same as Rails' `DATABASE_URL'.

#### Multiple Replica Environment Variables

To specific URLs for multiple replicas, replace the string `REPLICA` in the environment variable name with the replica name, in upper case. See the examples for replicas: `:replica1`, `:replica2`, and `:admin_replica`


    DATABASE_REPLICA1_URL='mysql://localhost/dbreplica1?pool=5&reconnect=true'
    DATABASE_REPLICA2_URL='postgresql://localhost:6432/ro_db?pool=5&reconnect=true'
    DATABASE_ADMIN_REPLICA_URL='postgresql://localhost:6432/admin_db?pool=5&reconnect=true'


### Master-only Models

It is possible to declare that specific models always use the DB master for all connections, using the `master_db_only!` method:

```ruby
class CustomerState < ActiveRecord::Base
  master_db_only!
end
```

All queries generated by methods on the `CustomerState` model will be directed to the DB master.

### Using FreshConnection With Unicorn

When using FreshConnection with Unicorn (or any other multi-processing web server which restarts processes on the fly), connection management needs special attention during startup:

```ruby
before_fork do |server, worker|
  ...
  ActiveRecord::Base.clear_all_replica_connections!
  ...
end
```

### Replica Connection Manager
The default replica connection manager is `FreshConnection::ConnectionManager`. If an alternative (custom) replica connection manager is desired, this can be done with a simple assignment within a Rails initializer:

`config/initializers/fresh_connection.rb`:

```ruby
FreshConnection.connection_manager = MyOwnReplicaConnection
```

The `MyOwnReplicaConnection` class should inherit from `FreshConnection::AbstractConnectionManager`, which has this interface:

```ruby
class MyOwnReplicaConnection < FreshConnection::AbstractConnectionManager

  def replica_connection
    # must return an instance of a subclass of ActiveRecord::ConnectionAdapters
    # eg: ActiveRecord::ConnectionAdapter::Mysql2Adapter
    # or: ActiveRecord::ConnectionAdapter::PostgresqlAdapter
  end

  def clear_all_connections!
    # called to disconnect all connections
  end

  def put_aside!
    # called when end of Rails controller action
  end

  def recovery?
    # called when raising exceptions on access to the DB replica
    # access will be retried when this method returns true
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

I'm glad that you would like to test!
To run the test suite, both `mysql` and `postgresql` must be installed.

### Test Configuration

First, configure the test servers in `test/config/*.yml`

Then, run:

```bash
./bin/setup
```

### Running Tests

To run the spec suite for all supported versions of rails:

```bash
./bin/test
```
