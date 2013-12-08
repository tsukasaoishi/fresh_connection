module FreshConnection
  class SlaveConnection
    COUNT = :fresh_connection_access_count
    TARGET = :fresh_connection_access_target

    class << self
      attr_writer :ignore_models, :ignore_configure_connection

      def raw_connection
        slave_connection.raw_connection
      end

      def slave_connection
        connection_manager.slave_connection
      end

      def put_aside!
        connection_manager.put_aside!
      end

      def manage_access(model_name, go_slave, &block)
        if ignore_model?(model_name)
          force_master_access(&block)
        else
          target = go_slave ? :slave : :master
          begin
            access_in(target)
            block.call
          ensure
            access_out
          end
        end
      end

      def slave_access?
        Thread.current[TARGET] == :slave
      end

      def ignore_model?(model_name)
        (@ignore_models || []).include?(model_name)
      end

      def ignore_configure_connection?
        !!@ignore_configure_connection
      end

      def connection_manager=(manager)
        @connection_manager_class = manager
      end

      private

      def force_master_access
        now_target = Thread.current[TARGET]
        Thread.current[TARGET] = :master
        yield
      ensure
        Thread.current[TARGET] = now_target
      end

      def access_in(target)
        Thread.current[COUNT] = (Thread.current[COUNT] || 0) + 1
        Thread.current[TARGET] ||= target
      end

      def access_out
        Thread.current[COUNT] -= 1
        if Thread.current[COUNT] == 0
          Thread.current[TARGET] = nil
          Thread.current[COUNT] = nil
        end
      end

      def connection_manager
        @connection_manager ||=
          (@connection_manager_class || FreshConnection::ConnectionManager).new
      end
    end
  end
end
