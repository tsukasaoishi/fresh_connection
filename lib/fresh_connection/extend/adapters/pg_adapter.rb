# frozen_string_literal: true
require 'fresh_connection/extend/adapters/base_adapter'

module FreshConnection
  module Extend
    module PgAdapter
      # Connection-specific caches/maps that must follow the borrowed replica raw
      # connection. On AR 7.2+ the @verified pin in BaseAdapter skips the master
      # adapter's configure_connection, so its @type_map / @type_map_for_results
      # can be nil; borrow the replica's (already configured) ones.
      REPLICA_IVARS =
        if BaseAdapter::MODERN_AR
          %i[@statements @type_map @type_map_for_results].freeze
        else
          %i[@statements].freeze
        end

      private

      def __change_connection
        return yield unless FreshConnection::AccessControl.replica_access?

        replica_connection = @model_class.replica_connection
        # Ensure the replica is connected/configured first: these ivars are only
        # populated after configure_connection runs.
        replica_connection.raw_connection

        saved = REPLICA_IVARS.map { |ivar| [ivar, instance_variable_get(ivar)] }
        begin
          REPLICA_IVARS.each do |ivar|
            instance_variable_set(ivar, replica_connection.instance_variable_get(ivar))
          end
          __with_replica_raw_connection(replica_connection) { yield }
        ensure
          saved.each { |ivar, value| instance_variable_set(ivar, value) }
        end
      end
    end
  end
end
