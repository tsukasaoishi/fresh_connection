# frozen_string_literal: true

module FreshConnection
  module Extend
    module BaseAdapter
      def self.prepended(base)
        base.send :attr_writer, :model_class
      end

      def log(*args)
        args[1] = "[#{__replica_spec_name}] #{args[1]}" if __replica_spec_name
        super
      end

      def select_all(*args)
        __change_connection { super }
      end

      def select_value(*args)
        __change_connection { super }
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
