# frozen_string_literal: true
require 'fresh_connection/extend/adapters/base_adapter'

module FreshConnection
  module Extend
    module M2Adapter
      private

      def __change_connection
        return yield unless FreshConnection::AccessControl.replica_access?

        replica_connection = @model_class.replica_connection
        __with_replica_raw_connection(replica_connection) { yield }
      end
    end
  end
end
