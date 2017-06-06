require 'active_record'
require 'concurrent'
require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_factory'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager

    if ActiveRecord::VERSION::MAJOR == 5
      include ::ActiveRecord::ConnectionAdapters::QueryCache::ConnectionPoolConfiguration
    end

    def initialize(*args)
      super
      @connections = Concurrent::Map.new
      if ActiveRecord::VERSION::MAJOR == 4
        @query_cache_enabled = Concurrent::Map.new { false }
      end
    end


    def replica_connection
      @connections.fetch_or_store(current_thread_id) do |_|
        connection_factory.new_connection(self)
      end
    end

    def put_aside!
      if (conn = @connections.delete(current_thread_id))
        conn.disconnect! rescue nil
      end
    end

    def clear_all_connections!
      for_all_connections do |conn|
        conn.disconnect! rescue nil
      end
      @connections.clear
    end

    def clear_replica_query_caches!
      for_all_connections do |conn|
        conn.clear_query_cache
      end
    end

    def enable_query_cache!
      for_all_connections do |conn|
        conn.enable_query_cache!
      end
    end

    def disable_query_cache!
      for_all_connections do |conn|
        conn.disable_query_cache!
      end
    end

    def recovery?
      return false if replica_connection.active?
      put_aside!
      true
    end

    private

    def for_all_connections
      @connections.each_value do |connection|
        yield(connection)
      end
    end

    def connection_factory
      @connection_factory ||= ConnectionFactory.new(@replica_group)
    end

    def current_thread_id
      Thread.current.object_id
    end
  end
end
