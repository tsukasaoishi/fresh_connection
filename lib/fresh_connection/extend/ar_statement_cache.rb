# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArStatementCache
      if FreshConnection.rails_52?
        def execute(params, connection, &block)
          klass.all.manage_access { super }
        end
      else
        def execute(params, klass, connection, &block)
          klass.all.manage_access { super }
        end
      end
    end
  end
end
