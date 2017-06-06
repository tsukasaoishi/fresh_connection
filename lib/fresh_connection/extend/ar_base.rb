require 'active_support/deprecation'
require 'fresh_connection/access_control'
require 'fresh_connection/replica_connection_handler'

module FreshConnection
  module Extend
    module ArBase
      def connection
        if FreshConnection::AccessControl.replica_access?
          if logger && logger.debug?
            replica_connection.tap{|c| c.replica_group = replica_group }
          else
            replica_connection
          end
        else
          super
        end
      end

      def read_master
        all.read_master
      end

      def with_master(&block)
        all.manage_access(false, &block)
      end

      def establish_fresh_connection(replica_group = "replica")
        replica_connection_handler.establish_connection(name, replica_group)
      end

      def master_connection
        superclass.connection
      end

      def replica_connection
        replica_connection_handler.connection(self)
      end

      def slave_connection
        ActiveSupport::Deprecation.warn(
          "'slave_connection' is deprecated and will removed from version 2.4.0. use 'replica_connection' instead."
        )

        replica_connection
      end

      def clear_all_replica_connections!
        replica_connection_handler.clear_all_connections!
      end

      def clear_all_slave_connections!
        ActiveSupport::Deprecation.warn(
          "'clear_all_slave_connections!' is deprecated and will removed from version 2.4.0. use 'clear_all_replica_connections!' instead."
        )

        clear_all_replica_connections!
      end

      def clear_all_query_caches!
        replica_connection_handler.clear_all_query_caches!
      end

      def enable_replica_query_cache_sync!
        FreshConnection::ReplicaConnectionHandler.enable_query_cache_sync!
      end

      def disable_replica_query_cache_sync!
        FreshConnection::ReplicaConnectionHandler.disable_query_cache_sync!
      end

      def replica_query_cache_sync
        FreshConnection::ReplicaConnectionHandler.replica_query_cache_sync
      end

      def master_db_only!
        @_fresh_connection_master_only = true
      end

      def master_db_only?
        @_fresh_connection_master_only ||=
          (self != ActiveRecord::Base && superclass.master_db_only?)
      end

      def replica_connection_put_aside!
        replica_connection_handler.put_aside!
      end

      def slave_connection_put_aside!
        ActiveSupport::Deprecation.warn(
          "'slave_connection_put_aside!' is deprecated and will removed from version 2.4.0. use 'replica_connection_put_aside!' instead."
        )

        replica_connection_put_aside!
      end

      def replica_connection_recovery?
        replica_connection_handler.recovery?(self)
      end

      def slave_connection_recovery?
        ActiveSupport::Deprecation.warn(
          "'slave_connection_recovery?' is deprecated and will removed from version 2.4.0. use 'replica_connection_recovery?' instead."
        )

        replica_connection_recovery?
      end

      def replica_group
        replica_connection_handler.replica_group(self)
      end

      def slave_group
        ActiveSupport::Deprecation.warn(
          "'slave_connection_recovery?' is deprecated and will removed from version 2.4.0. use 'replica_connection_recovery?' instead."
        )

        replica_group
      end

      private

      def replica_connection_handler
        @@replica_connection_handler ||= FreshConnection::ReplicaConnectionHandler.new
      end
    end
  end
end
