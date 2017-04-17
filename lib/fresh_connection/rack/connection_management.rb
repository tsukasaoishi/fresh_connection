module FreshConnection
  module Rack
    class ConnectionManagement
      def initialize(app)
        @app = app
      end

      def call(env)
        testing = env['rack.test']

        response = @app.call(env)
        response[2] = ::Rack::BodyProxy.new(response[2]) do
          ActiveRecord::Base.replica_connection_put_aside! unless testing
        end

        response
      rescue Exception
        ActiveRecord::Base.replica_connection_put_aside! unless testing
        raise
      end
    end
  end
end
