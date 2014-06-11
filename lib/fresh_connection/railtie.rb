require 'fresh_connection/rack/connection_management'
require 'rails'

module FreshConnection
  class Railtie < Rails::Railtie
    config.fresh_connection = ActiveSupport::OrderedOptions.new
    config.eager_load_namespaces << FreshConnection

    initializer "fresh_connection.configure_rails_initialization" do |app|
      ActiveSupport.on_load(:active_record) do
        app.config.app_middleware.swap(
          ActiveRecord::ConnectionAdapters::ConnectionManagement,
          FreshConnection::Rack::ConnectionManagement
        )

        Initializer.extend_active_record
      end
    end
  end
end
