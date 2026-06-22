# FreshConnection
[![Gem Version](https://badge.fury.io/rb/fresh_connection.svg)](http://badge.fury.io/rb/fresh_connection) [![test](https://github.com/tsukasaoishi/fresh_connection/actions/workflows/test.yml/badge.svg)](https://github.com/tsukasaoishi/fresh_connection/actions/workflows/test.yml) [![Code Climate](https://codeclimate.com/github/tsukasaoishi/fresh_connection/badges/gpa.svg)](https://codeclimate.com/github/tsukasaoishi/fresh_connection)

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
When one of the replicas becomes unreachable for any reason, FreshConnection retries the query, making up to three attempts in total to reach a replica via the load balancer.  

Removing a trouble replica from a cluster is a work of the load balancer.  
FreshConnection expects the load balancer to route around the failed replica within those attempts.  

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

- FreshConnection supports ActiveRecord 6.1, 7.2, 8.0 and 8.1.
- If you are using ActiveRecord 5.2 / 6.0, you can use FreshConnection version 3.1.3 or before.
- If you are using Rails 5.1, you can use FreshConnection version 3.0.3 or before.

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
database configuration file, `config/database.yml`. Give the replica its own
name (for example `db_replica`) and connect your models to it with
`establish_fresh_connection`.

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

  db_replica:
    username: replica_db_user
    password: <%= ENV['REPLICA_DATABASE_PASSWORD'] %>
    host: replica_db
```

Then connect your models to the replica, usually once in `ApplicationRecord`:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_fresh_connection :db_replica
end
```

`db_replica` is the configuration used for connecting read-only queries to the database replica. All other connections use the database master settings.

**NOTE:** 
Do not name the stanza `replica`; it has a special meaning in the Rails 6+ multi-database configuration.  
Use a different name (such as `db_replica`) and reference it with `establish_fresh_connection`, as shown above.

### Multiple DB Replicas
If you want to use multiple configured DB replicas, the configuration can contain multiple replica stanzas in the configuration file `config/database.yml`.

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

  db_replica:
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

class Customer < ApplicationRecord
end
```

The `AdminUser` and `Benefit` models will access the database configured for the `admin_replica` group.

The `Customer` model will use the default connections: read-only queries will connect to the standard DB replica, and state-changing queries will connect to the DB master.


### Replica Configuration With Environment Variables

Alternative to using a configuration in the `database.yml` file, it is possible to completely specify the replica access components using environment variables.

The environment variable corresponding to the `:db_replica` group is `DATABASE_DB_REPLICA_URL`.  
The URL string components are the same as Rails' `DATABASE_URL`.

#### Multiple Replica Environment Variables

To specify URLs for multiple replicas, set `DATABASE_<NAME>_URL`, where `<NAME>` is the replica name in upper case. See the examples for replicas `:replica1`, `:replica2`, and `:admin_replica`:


    DATABASE_REPLICA1_URL='mysql2://localhost/dbreplica1?pool=5&reconnect=true'
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
    # must return an instance of a subclass of ActiveRecord::ConnectionAdapters::AbstractAdapter
    # eg: ActiveRecord::ConnectionAdapters::Mysql2Adapter
    # or: ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
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

To run the test suite, local `mysql` and `postgresql` servers must be running.

### Setup

Install the dependencies (gems and the Appraisal gemfiles):

```bash
./bin/setup
```

### Running Tests

Run the suite against both MySQL and PostgreSQL for all supported versions of Rails:

```bash
./bin/test
```

By default `bin/test` connects to MySQL and PostgreSQL on `localhost`. To point at
different servers, set `DATABASE_URL`, `DATABASE_REPLICA1_URL`,
`DATABASE_REPLICA2_URL` and `DATABASE_FAKE_REPLICA_URL` before running it.
