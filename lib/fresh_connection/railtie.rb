require "fresh_connection/rack/connection_management"
require 'fresh_connection/extend/ar_base'
require 'fresh_connection/extend/ar_relation'
require 'fresh_connection/extend/mysql2_adapter'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      app.config.middleware.swap(
        ActiveRecord::ConnectionAdapters::ConnectionManagement,
        FreshConnection::Rack::ConnectionManagement
      )

      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.extend FreshConnection::Extend::ArBase

        ActiveRecord::Relation.__send__(:include, FreshConnection::Extend::ArRelation)

        ActiveRecord::ConnectionAdapters::Mysql2Adapter.__send__(
          :include, FreshConnection::Extend::Mysql2Adapter
        )
      end
    end
  end
end
