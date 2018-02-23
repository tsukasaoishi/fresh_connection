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

If you wish to use multiple DB replicas on any given connection but do not have a load balancer (such as [`pgbouncer`](https://pgbouncer.github.io) for Posgres databases), you can use [EbisuConnection](https://github.com/tsukasaoishi/ebisu_connection).

## Usage
### Access to the DB Replica
Read queries are automatically connected to the DB replica.

```ruby
Article.where(id: 1)

Account.count
```

### Access to the DB Master
If you wish to ensure that queries are directed to the DB master, call `read_master`.

> Note: Before version 0.4.3, `readonly(false)` must be used.

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

- FreshConnection supports ActiveRecord version 5.0 or later.
- If you are using Rails 4.2, you can use FreshConnection version 2.4.4 or before.
- If you are using Rails 4.1 or 4.0, you can use FreshConnection version 2.1.2 or before.
- If you are using Rails 3.2, you can use FreshConnection version 1.0.0 or before.

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

### Variant Installation For Use With Some Other ActiveRecord Gems

If you are using NewRelic or other gems that insert themselves into the ActiveRecord call-chain using `method_alias`, then a slight variation on the installation and configuration is required.

In the `Gemfile`, use:

```ruby
gem "fresh_connection", require: false
```

Then, in `config/application.rb`, add the following:

```ruby
config.after_initialize do
  require 'fresh_connection'
end
```

## Configuration

The FreshConnection database replica is configured within the standard Rails
database configuration file, `config/database.yml`, using a `replica:` stanza.

*Security Note*:

> We strongly recommend against using secrets within the `config/database.yml`
> file.  Instead, it is both convenient and advisable to use ERB substitutions with 
> environment variables within the file.

> Using the [`dotenv`](https://github.com/bkeepers/dotenv) gem to keep secrets in a `.env` file that is never committed 
> to the source management repository will help make secrets manageable.

Below is a sample such configuration file.

### `config/database.yml`

```yaml
production:
  adapter:   mysql2
  encoding:  utf8
  reconnect: true
  database:  <%= ENV['DB_MASTER_NAME'] %>
  pool:      5
  username:  <%= ENV['DB_MASTER_USER'] %>
  password:  <%= ENV['DB_MASTER_PASS'] %>
  host:      <%= ENV['DB_MASTER_HOST'] %>
  socket:    /var/run/mysqld/mysqld.sock

  replica:
    username: <%= ENV['DB_REPLICA_USER'] %>
    password: <%= ENV['DB_REPLICA_PASS'] %>
    host:     <%= ENV['DB_REPLICA_HOST'] %>
```

`replica` is the configuration used for connecting read-only queries to the database replica.  All other connections will use the database master settings.

### Multiple DB Replicas
If you want to use multiple configured DB replicas, the configuration can contain multiple `replica` stanzas in the configuration file `config/database.yml`.

For example:

```yaml
production:
  adapter:   mysql2
  encoding:  utf8
  reconnect: true
  database:  <%= ENV['DB_MASTER_NAME'] %>
  pool:      5
  username:  <%= ENV['DB_MASTER_USER'] %>
  password:  <%= ENV['DB_MASTER_PASS'] %>
  host:      <%= ENV['DB_MASTER_HOST'] %>
  socket:    /var/run/mysqld/mysqld.sock

  replica:
    username: <%= ENV['DB_REPLICA_USER'] %>
    password: <%= ENV['DB_REPLICA_PASS'] %>
    host:     <%= ENV['DB_REPLICA_HOST'] %>

  admin_replica:
    username: <%= ENV['DB_ADMIN_REPLICA_USER'] %>
    password: <%= ENV['DB_ADMIN_REPLICA_PASS'] %>
    host:     <%= ENV['DB_ADMIN_REPLICA_HOST'] %>
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

The environment variables corresponding to the `:replica` group are `DATABASE_REPLICA_URL` and `DATABASE_REPLICA1_URL`, with the latter being used only if the former is not defined.

The URL value is a [URL](https://en.wikipedia.org/wiki/URL) string with the following components:

   _adapter://dbuser:dbpass@dbhost:dbport/dbname?querypath_

where the components are:

| Component | Purpose | Examples  |
| --------- | ------- | --------- |
| _adapter_ | Declares the database adapter | `mysql`, `postgresql` |
| _dbuser_  | The login for the database | `root`, `postgres` |
| _dbpass_  | The password for the database | |
| _dbhost_ | The hostname for the database | `db1`, `localhost` |
| _dbport_ | The port for the database connection | `3306`, `5432` |
| _dbname_ | The name of the database | `mydb`, `appdb`, etc. |
| _querypath_ | One or more variable assignments: _var1=val1_, separated by '&' | `pools=5&reconnect=true` |


For example, here is a URL appropriate for a connection to a test database on the local host, on a custom port:

    export DATABASE_REPLICA_URL='postgresql://root:somepw@localhost:6432/test_db?pool=5&reconnect=true

### Multiple Replica Environment Variables

To specific URLs for multiple replicas, replace the string `REPLICA` in the environment variable name with the replica name, in upper case. See the examples for replicas: `:replica1`, `:replica2`, and `:admin_replica`


    ENVIRONMENT_REPLICA1_URL='mysql://localhost/dbreplica1?pool=5&reconnect=true'
    ENVIRONMENT_REPLICA2_URL='postgresql://localhost:6432/ro_db?pool=5&reconnect=true'
    ENVIRONMENT_ADMIN_REPLICA_URL='postgresql://localhost:6432/admin_db?pool=5&reconnect=true'

### Special-Case Replica URL

When `:replica` is used but `DATABASE_REPLICA_URL` is *not* defined, then the value of `DATABASE_REPLICA1_URL` will be used if it is defined.

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

after_fork do |server, worker|
  ...
  ActiveRecord::Base.establish_fresh_connection
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
