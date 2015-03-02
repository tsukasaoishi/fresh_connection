module FreshConnection
  module Extend
    module ArStatementCache
      def self.included(base)
        base.alias_method_chain :execute, :fresh_connection
      end

      def execute_with_fresh_connection(params, klass, connection)
        klass.manage_access(klass.all.enable_slave_access) do
          execute_without_fresh_connection(params, klass, connection)
        end
      end
    end
  end
end
