module FreshConnection
  module Rack
    class ConnectionManagement < ActiveRecord::ConnectionAdapters::ConnectionManagement
      def call(env)
        super
      ensure
        FreshConnection.put_aside! unless env.key?("rack.test")
      end
    end
  end
end
