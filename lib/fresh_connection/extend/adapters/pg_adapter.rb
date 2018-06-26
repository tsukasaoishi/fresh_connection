# frozen_string_literal: true
require 'fresh_connection/extend/adapters/base_adapter'

module FreshConnection
  module Extend
    module PgAdapter
      private

      def __change_connection
        return yield unless FreshConnection::AccessControl.replica_access?

        master_connection = @connection
        master_statements = @statements
        begin
          replica_connection = @model_class.replica_connection
          @connection = replica_connection.raw_connection
          @statements = replica_connection.instance_variable_get(:@statements)
          yield
        ensure
          @connection = master_connection
          @statements = master_statements
        end
      end
    end
  end
end
