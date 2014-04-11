# FreshConnection

FreshConnection supports to connect with Mysql slave servers via Load Balancers.
All connections will be disconnected every time at the end of the action.

## Installation

### For Rails3 and 4
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

slave is config to connect to slave servers.
Others will use the master setting. If you want to change, write in the slave.

### Declare model that doesn't use slave db

    class SomethingModel < ActiveRecord::Base
      master_db_only!
    end

If model that always access to master servers is exist, You may want to write ```master_db_only!```  in model.
The model that master_db_only model's child is always access to master db.

### Slave Connection Manager
Default slave connection manager is FreshConnection::ConnectionManager.
If you would like to change slave connection manager, assign yourself slave connection manager.

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

## Usage
Read query will be access to slave server.

    Article.where(:id => 1)

If you want to access to master saver, use readonly(false).

    Article.where(:id => 1).readonly(false)

In transaction, Always will be access to master server.

    Article.transaction do
      Article.where(:id => 1)
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

```bash
bundle install --path bundle
GEM_HOME=bundle/ruby/(your ruby version) gem install bundler --pre
bundle exec appraisal install
```

This command run the spec suite for all rails versions supported.

```base
bundle exec appraisal rake spec
```

