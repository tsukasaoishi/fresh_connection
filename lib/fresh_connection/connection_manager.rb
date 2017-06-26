require 'concurrent'
require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_factory'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def initialize(*args)
      super

      config = connection_factory.spec
      resolver = ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(spec_name => config)
      spec = resolver.spec(spec_name.to_sym)

      @pool = ::ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end

    def replica_connection
      @pool.connection
    end

    def put_aside!
      @pool.release_connection if @pool.active_connection? && !@pool.connection.transaction_open?
    end

    def clear_all_connections!
      @pool.disconnect!
    end

    def recovery?
      return false if replica_connection.active?
      put_aside!
      true
    end

    private

    def connection_factory
      @connection_factory ||= ConnectionFactory.new(spec_name)
    end
  end
end
