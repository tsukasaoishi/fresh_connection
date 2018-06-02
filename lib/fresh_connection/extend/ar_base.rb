# frozen_string_literal: true
require 'fresh_connection/access_control'
require 'fresh_connection/replica_connection_handler'

module FreshConnection
  module Extend
    module ArBase
      def read_master
        all.read_master
      end

      def with_master(&block)
        FreshConnection::AccessControl.manage_access(
          model: self,
          replica_access: false,
          &block
        )
      end

      def connection
        super.tap {|c| c.model_class = self }
      end

      def replica_connection
        __replica_handler.connection(replica_spec_name)
      end

      def clear_all_replica_connections!
        __replica_handler.clear_all_connections!
      end

      def establish_fresh_connection(spec_name = nil)
        spec_name = spec_name.to_s
        spec_name = "replica" if spec_name.empty?
        @_replica_spec_name = spec_name

        __replica_handler.refresh_connection(replica_spec_name)
      end

      def master_db_only!
        @_fresh_connection_master_only = true
      end

      def master_db_only?
        @_fresh_connection_master_only ||=
          (self != ActiveRecord::Base && superclass.master_db_only?)
      end

      def replica_spec_name
        @_replica_spec_name ||= __search_replica_spec_name
      end

      private

      def __search_replica_spec_name
        if self == ActiveRecord::Base
          "replica"
        else
          superclass.replica_spec_name
        end
      end

      def __replica_handler
        FreshConnection::ReplicaConnectionHandler.instance
      end
    end
  end
end
