module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def slave_connection
      synchronize do
        slave_connections[current_thread_id] ||= connection_factory.new_connection
      end
    end

    def put_aside!
      synchronize do
        if c = slave_connections.delete(current_thread_id)
          c.disconnect! rescue nil
        end
      end
    end

    def clear_all_connections!
      synchronize do
        slave_connections.values.each {|c| c.disconnect! rescue nil }
        @slave_connections.clear
      end
    end

    def recovery(failure_connection, exception)
      do_recovery = slave_down_message?(exception.message)
      put_aside! if do_recovery
      do_recovery
    end

    private

    def slave_connections
      @slave_connections ||= {}
    end

    def connection_factory
      @connection_factory ||= ConnectionFactory.new(@slave_group)
    end
  end
end
