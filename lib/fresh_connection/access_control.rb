module FreshConnection
  class AccessControl
    RETRY_LIMIT = 10

    class << self
      attr_writer :ignore_configure_connection

      delegate :slave_connection, :put_aside!, :recoverable?, :recovery, :to => :connection_manager

      def manage_access(model_klass, enable_slave_access, &block)
        if model_klass.master_db_only?
          force_master_access(&block)
        else
          begin
            access_in(enable_slave_access ? :slave : :master)
            block.call
          ensure
            access_out
          end
        end
      end

      def slave_access?
        access_db == :slave
      end

      def ignore_configure_connection?
        !!@ignore_configure_connection
      end

      def connection_manager=(manager)
        @connection_manager_class = manager
      end

      def retry_limit
        RETRY_LIMIT
      end

      private

      def access_in(db)
        increment_access_count
        access_to(db) unless access_db
      end

      def access_out
        decrement_access_count
        access_to(nil) if access_count == 0
      end

      def force_master_access
        db = access_db
        access_to(:master)
        yield
      ensure
        access_to(db)
      end

      def connection_manager
        @connection_manager ||=
          (@connection_manager_class || FreshConnection::ConnectionManager).new
      end

      def access_db
        Thread.current[:fresh_connection_access_target]
      end

      def access_to(db)
        Thread.current[:fresh_connection_access_target] = db
      end

      def access_count
        Thread.current['fresh_connection_access_count'] || 0
      end

      def increment_access_count
        Thread.current['fresh_connection_access_count'] = access_count + 1
      end

      def decrement_access_count
        Thread.current['fresh_connection_access_count'] = access_count - 1
      end
    end
  end
end
