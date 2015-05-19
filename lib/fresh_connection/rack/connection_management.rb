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
          clear_connections! unless testing
        end

        response
      rescue Exception
        clear_connections! unless testing
        raise
      end

      private

      def clear_connections!
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.put_aside!
      end
    end
  end
end
