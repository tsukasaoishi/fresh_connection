require 'fresh_connection/rack/connection_management'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      ActiveSupport.on_load(:active_record) do
        app.config.middleware.insert_after(
          ActiveRecord::ConnectionAdapters::ConnectionManagement,
          FreshConnection::Rack::ConnectionManagement
        )
      end
    end
  end
end
