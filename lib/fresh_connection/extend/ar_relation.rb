require 'active_support/deprecation'

module FreshConnection
  module Extend
    module ArRelation
      RETRY_LIMIT = 3
      private_constant :RETRY_LIMIT

      def manage_access(replica_access = enable_replica_access, &block)
        if @klass.master_db_only?
          FreshConnection::AccessControl.force_master_access(&block)
        else
          retry_count = 0
          begin
            FreshConnection::AccessControl.access(replica_access, &block)
          rescue *FreshConnection::AccessControl.catch_exceptions
            if @klass.replica_connection_recovery?
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
        self.read_master_value = true
        self
      end

      def read_master_value
        @values[:read_master]
      end

      def read_master_value=(value)
        raise ImmutableRelation if @loaded
        @values[:read_master] = value
      end

      def enable_replica_access
        connection.open_transactions == 0 && !read_master_value
      end

      def enable_slave_access
        ActiveSupport::Deprecation.warn(
          "'enable_slave_access' is deprecated and will removed from version 2.4.0. use 'enable_replica_access' insted."
        )

        enable_replica_access
      end

      private

      def exec_queries
        manage_access { super }
      end
    end
  end
end
