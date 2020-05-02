# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArStatementCache
      def execute(params, connection, &block)
        klass.all.manage_access { super }
      end
    end
  end
end
