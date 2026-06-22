# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArStatementCache
      def execute(params, connection, **, &block)
        __fc_model.all.manage_access { super }
      end

      private

      # ActiveRecord 8.0+ stores the model in @model and no longer exposes a
      # `klass` reader on StatementCache; 6.1 / 7.2 use @klass.
      def __fc_model
        defined?(@model) ? @model : @klass
      end
    end
  end
end
