require 'fresh_connection/rack/connection_management'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      if defined?(ActiveRecord::ConnectionAdapters::ConnectionManagement)
        app.config.app_middleware.insert_before(
          ActiveRecord::ConnectionAdapters::ConnectionManagement,
          FreshConnection::Rack::ConnectionManagement
        )
      else
        app.config.app_middleware.insert_before(
          ActionDispatch::Executor,
          FreshConnection::Rack::ConnectionManagement
        )
      end
    end
  end
end
