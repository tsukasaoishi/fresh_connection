require 'fresh_connection/abstract_connection_manager'

module FreshConnection
  class ConnectionManager < AbstractConnectionManager
    def slave_connection
      synchronize do
        slave_connections[current_thread_id] ||= new_connection
      end
    end

    def put_aside!
      synchronize do
        if c = slave_connections.delete(current_thread_id)
          c.disconnect! rescue nil
        end
      end
    end

    def recovery(failure_connection, exception)
      if recoverable? && slave_down_message?(exception.message)
        put_aside!
        true
      else
        false
      end
    end

    def recoverable?
      true
    end

    private

    def slave_connections
      @slave_connections ||= {}
    end

    def new_connection
      ActiveRecord::Base.send("mysql2_connection", spec)
    end

    def spec
      @spec ||= get_spec
    end

    def get_spec
      ret = ActiveRecord::Base.configurations[Rails.env]
      ret.merge(ret[@slave_group] || {})
    end
  end
end
