require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_specification'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def initialize(*args)
      super

      spec = FreshConnection::ConnectionSpecification.new(spec_name).spec
      @pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end

    def replica_connection
      @pool.connection
    end

    def put_aside!
      return unless @pool.active_connection?

      conn = replica_connection
      return if conn.transaction_open?

      @pool.release_connection
      @pool.remove(conn)
      conn.disconnect!
    end

    def clear_all_connections!
      @pool.disconnect!
    end

    def recovery?
      c = replica_connection rescue nil
      return false if c && c.active?
      put_aside!
      true
    end
  end
end
