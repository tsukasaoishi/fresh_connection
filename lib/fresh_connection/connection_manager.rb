require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_factory'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def slave_connection
      synchronize do
        slave_connections[current_thread_id] ||= connection_factory.new_connection
      end
    end

    def put_aside!
      synchronize do
        slave_connections.values.each {|c| c.disconnect! rescue nil }
        @slave_connections.clear
      end
    end
    alias_method :clear_all_connections!, :put_aside!

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
