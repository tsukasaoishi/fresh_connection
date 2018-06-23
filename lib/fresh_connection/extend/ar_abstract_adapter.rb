# frozen_string_literal: true
require 'fresh_connection/check_adapter'

module FreshConnection
  module Extend
    module ArAbstractAdapter
      def inherited(klass)
        case FreshConnection::CheckAdapter.check(klass)
        when :mysql
          klass.prepend BaseAdapter
          require 'fresh_connection/extend/adapters/m2_adapter'
          klass.prepend M2Adapter
        when :postgresql
          klass.prepend BaseAdapter
          require 'fresh_connection/extend/adapters/pg_adapter'
          klass.prepend PgAdapter
        end
      end
    end

    module BaseAdapter
      def self.prepended(base)
        base.send :attr_writer, :model_class
      end

      def log(*args)
        args[1] = "[#{__replica_spec_name}] #{args[1]}" if __replica_spec_name
        super
      end

      def select_all(*args)
        change_connection { super }
      end

      def select_value(*args)
        change_connection { super }
      end

      private

      def __replica_spec_name
        return nil if !defined?(@model_class) || !@model_class
        return nil unless FreshConnection::AccessControl.replica_access?
        @model_class.replica_spec_name
      end
    end
  end
end
