module FreshConnection
  module Extend
    module ArStatementCache
      def execute(params, klass, connection)
        klass.all.manage_access { super }
      end
    end
  end
end
