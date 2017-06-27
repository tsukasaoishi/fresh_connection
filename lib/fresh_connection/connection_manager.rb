require 'concurrent'
require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_specification'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def initialize(*args)
      super

      spec = FreshConnection::ConnectionSpecification.new(spec_name).spec
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
  end
end
