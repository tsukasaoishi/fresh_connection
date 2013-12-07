# FreshConnection

FreshConnection supports to connect with Mysql slave servers via Load Balancers.
All connections will be disconnected every time at the end of the action.

## Installation

### For Rails3
Add this line to your application's Gemfile:

    gem "fresh_connection"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fresh_connection

### For Rails2.3

    $ gem install fresh_connection -v 0.0.7

## Config
#### config/database.yml

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

### config/initializers/fresh_connection.rb

    FreshConnection::SlaveConnection.ignore_models = %w|Model1 Model2|

If models that ignore access to slave servers is exist, You can write model name at FreshConnection::SlaveConnection.ignore models.

### use config/environment.rb if rails2.3

    require 'fresh_connection'
    ActionController::Dispatcher.middleware.swap ActiveRecord::ConnectionAdapters::ConnectionManagement, FreshConnection::Rack::ConnectionManagement

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
