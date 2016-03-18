require 'concurrent'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def initialize(*args)
      super
      @connections = Concurrent::Map.new
    end

    def slave_connection
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

    def recovery(exception)
      do_recovery = slave_down_message?(exception.message)
      put_aside! if do_recovery
      do_recovery
    end

    private

    def connection_factory
      @connection_factory ||= ConnectionFactory.new(@slave_group)
    end

    def adapter_method
      connection_factory.adapter_method
    end

    def current_thread_id
      Thread.current.object_id
    end
  end
end
