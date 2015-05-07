module FreshConnection
  module Extend
    module ArStatementCache
      def execute(params, klass, connection)
        klass.manage_access(klass.all.enable_slave_access) do
          super
        end
      end
    end
  end
end
