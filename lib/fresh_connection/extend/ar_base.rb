require 'fresh_connection/access_control'
require 'fresh_connection/replica_connection_handler'

module FreshConnection
  module Extend
    module ArBase
      def replica_connection_specification_name
        if defined?(@replica_connection_specification_name)
          return @replica_connection_specification_name
        end

        if self == ActiveRecord::Base
          "replica"
        else
          superclass.replica_connection_specification_name
        end
      end

      def replica_connection_specification_name=(spec_name)
        spec_name = spec_name.to_s
        spec_name = "replica" if spec_name.empty? || spec_name == "slave"

        @replica_connection_specification_name = spec_name
      end

      def connection
        master_c = super
        return master_c unless FreshConnection::AccessControl.replica_access?

        replica_c = replica_connection
        replica_c.master_connection = master_c
        replica_c.replica_spec_name = replica_connection_specification_name if logger && logger.debug?
        replica_c
      end

      def read_master
        all.read_master
      end

      def with_master(&block)
        all.manage_access(false, &block)
      end

      def establish_fresh_connection(spec_name = "replica")
        self.replica_connection_specification_name = spec_name
        replica_connection_handler.establish_connection(replica_connection_specification_name)
      end

      def replica_connection
        replica_connection_handler.connection(replica_connection_specification_name)
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
        replica_connection_handler.recovery?(replica_connection_specification_name)
      end

      private

      def replica_connection_handler
        FreshConnection::ReplicaConnectionHandler.instance
      end
    end
  end
end
