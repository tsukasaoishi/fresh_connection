module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      app.config.middleware.swap(
        ActiveRecord::ConnectionAdapters::ConnectionManagement,
        FreshConnection::Rack::ConnectionManagement
      )
    end
  end
end
