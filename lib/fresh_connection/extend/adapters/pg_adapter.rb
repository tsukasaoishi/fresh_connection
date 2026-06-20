# frozen_string_literal: true
require 'fresh_connection/extend/adapters/base_adapter'

module FreshConnection
  module Extend
    module PgAdapter
      private

      def __change_connection
        return yield unless FreshConnection::AccessControl.replica_access?

        replica_connection = @model_class.replica_connection
        # Ensure the replica is connected/configured first: its @statements and
        # @type_map_for_results are only populated after configure_connection runs.
        replica_connection.raw_connection
        master_statements = @statements
        # On AR 7.2+ the @verified pin in BaseAdapter skips configure_connection,
        # so a master adapter that has never run a query has a nil
        # @type_map_for_results. Borrow the replica's (already configured) one.
        master_type_map = @type_map_for_results if BaseAdapter::MODERN_AR
        begin
          @statements = replica_connection.instance_variable_get(:@statements)
          if BaseAdapter::MODERN_AR
            @type_map_for_results = replica_connection.instance_variable_get(:@type_map_for_results)
          end
          __with_replica_raw_connection(replica_connection) { yield }
        ensure
          @statements = master_statements
          @type_map_for_results = master_type_map if BaseAdapter::MODERN_AR
        end
      end
    end
  end
end
