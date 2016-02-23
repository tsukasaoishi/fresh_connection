module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def initialize(*args)
      super
      @connections = ThreadSafeValue.new
    end

    def slave_connection
      connections.fetch do |conn|
        conn || connections.store(connection_factory.new_connection)
      end
    end

    def put_aside!
      connections.delete do |conn|
        conn && conn.disconnect! rescue nil
      end
    end

    def clear_all_connections!
      connections.all do |conns|
        conns.each {|c| c.disconnect! rescue nil }
        connections.clear
      end
    end

    def recovery(failure_connection, exception)
      do_recovery = slave_down_message?(exception.message)
      put_aside! if do_recovery
      do_recovery
    end

    private

    def connections
      @connections
    end

    def connection_factory
      @connection_factory ||= ConnectionFactory.new(@slave_group)
    end
  end
end
