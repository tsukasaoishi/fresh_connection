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
      do_recovery = slave_down_message?(exception.message)
      put_aside! if do_recovery
      do_recovery
    end

    private

    def slave_connections
      @slave_connections ||= {}
    end

    def new_connection
      ActiveRecord::Base.send(adapter_method, spec)
    end

    def adapter_method
      @adapter_method ||= ActiveRecord::Base.connection_pool.spec.adapter_method
    end

    def spec
      @spec ||= get_spec
    end

    def get_spec
      ret = ActiveRecord::Base.connection_pool.spec.config
      ret.merge(ret[slave_group.to_sym] || {})
    end
  end
end
