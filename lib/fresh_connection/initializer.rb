require 'fresh_connection/rack/connection_management'
require 'fresh_connection/extend/ar_base'
require 'fresh_connection/extend/ar_relation'
require 'fresh_connection/extend/connection_handler'
require 'fresh_connection/extend/mysql2_adapter'

module FreshConnection
  class Initializer
    class << self
      def swap_rack(app)
        app.config.middleware.swap(
          ActiveRecord::ConnectionAdapters::ConnectionManagement,
          FreshConnection::Rack::ConnectionManagement
        )
      end

      def extend_active_record
        ActiveRecord::Base.extend FreshConnection::Extend::ArBase

        ActiveRecord::Relation.__send__(:include, FreshConnection::Extend::ArRelation)

        ActiveRecord::ConnectionAdapters::ConnectionHandler.__send__(
          :include, FreshConnection::Extend::ConnectionHandler
        )

        require 'active_record/connection_adapters/mysql2_adapter'
        ActiveRecord::ConnectionAdapters::Mysql2Adapter.__send__(
          :include, FreshConnection::Extend::Mysql2Adapter
        )

        ActiveRecord::Base.establish_fresh_connection
      end
    end
  end
end
