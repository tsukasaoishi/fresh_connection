module FreshConnection
  module Extend
    module ArRelation
      RETRY_LIMIT = 3
      private_constant :RETRY_LIMIT

      def manage_access(slave_access = enable_slave_access, &block)
        if @klass.master_db_only?
          FreshConnection::AccessControl.force_master_access(&block)
        else
          retry_count = 0
          begin
            FreshConnection::AccessControl.access(slave_access, &block)
          rescue *FreshConnection::AccessControl.catch_exceptions
            if @klass.slave_connection_recovery?
              retry_count += 1
              retry if retry_count < RETRY_LIMIT
            end

            raise
          end
        end
      end

      def calculate(*args)
        manage_access { super }
      end

      def exists?(*args)
        manage_access { super }
      end

      def pluck(*args)
        manage_access { super }
      end

      def read_master
        spawn.read_master!
      end

      def read_master!
        @read_from_master = true
        self
      end

      def enable_slave_access
        connection.open_transactions == 0 && @read_from_master.nil?
      end

      private

      def exec_queries
        manage_access { super }
      end
    end
  end
end
