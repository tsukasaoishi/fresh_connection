module FreshConnection
  module Rack
    class ConnectionManagement
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        unless env.key?("rack.test")
          if FreshConnection::SlaveConnection.master_clear_connection?
            ActiveRecord::Base.clear_all_connections!
          else
            ActiveRecord::Base.clear_active_connections!
          end
          FreshConnection::SlaveConnection.clear_all_connections!
        end
      end
    end
  end
end
