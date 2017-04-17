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

      def establish_fresh_connection(replica_group = nil)
        replica_connection_handler.establish_connection(name, replica_group)
      end

      def replica_connection
        replica_connection_handler.connection(self)
      end

      def clear_all_replica_connections!
        replica_connection_handler.clear_all_connections!
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

      def replica_connection_recovery?
        replica_connection_handler.recovery?(self)
      end

      def replica_group
        replica_connection_handler.replica_group(self)
      end

      private

      def replica_connection_handler
        @@replica_connection_handler ||= FreshConnection::ReplicaConnectionHandler.new
      end
    end
  end
end
