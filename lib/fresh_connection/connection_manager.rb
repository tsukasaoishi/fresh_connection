require 'concurrent'
require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_factory'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def initialize(*args)
      super
      @connections = Concurrent::Map.new
    end

    def replica_connection
      @connections.fetch_or_store(current_thread_id) do |_|
        connection_factory.new_connection
      end
    end

    def put_aside!
      conn = @connections.delete(current_thread_id)
      return unless conn
      conn && conn.disconnect! rescue nil
    end

    def clear_all_connections!
      @connections.each_value do |conn|
        conn.disconnect! rescue nil
      end
      @connections.clear
    end

    def recovery?
      return false if replica_connection.active?
      put_aside!
      true
    end

    private

    def connection_factory
      @connection_factory ||= ConnectionFactory.new(@replica_group)
    end

    def current_thread_id
      Thread.current.object_id
    end
  end
end
