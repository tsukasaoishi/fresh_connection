# frozen_string_literal: true
require 'fresh_connection/extend/adapters/base_adapter'

module FreshConnection
  module Extend
    module M2Adapter
      private

      def __change_connection
        return yield unless FreshConnection::AccessControl.replica_access?

        master_connection = @connection
        begin
          replica_connection = @model_class.replica_connection
          @connection = replica_connection.raw_connection
          yield
        ensure
          @connection = master_connection
        end
      end
    end
  end
end
