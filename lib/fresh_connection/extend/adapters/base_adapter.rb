# frozen_string_literal: true

module FreshConnection
  module Extend
    module BaseAdapter
      MODERN_AR = ActiveRecord::VERSION::MAJOR >= 7
      RAW_CONNECTION_IVAR = MODERN_AR ? :@raw_connection : :@connection

      def self.prepended(base)
        base.send :attr_writer, :model_class
      end

      def log(*args, **kwargs, &block)
        args[1] = "[#{__replica_spec_name}] #{args[1]}" if __replica_spec_name
        super
      end

      def select_all(*, **)
        __change_connection { super }
      end

      def select_value(*, **)
        __change_connection { super }
      end

      private

      def __with_replica_raw_connection(replica)
        master_raw = instance_variable_get(RAW_CONNECTION_IVAR)
        master_verified = @verified if MODERN_AR
        begin
          instance_variable_set(RAW_CONNECTION_IVAR, replica.raw_connection)
          @verified = true if MODERN_AR
          yield
        ensure
          instance_variable_set(RAW_CONNECTION_IVAR, master_raw)
          @verified = master_verified if MODERN_AR
        end
      end

      def __replica_spec_name
        return nil if !defined?(@model_class) || !@model_class
        return nil unless FreshConnection::AccessControl.replica_access?
        @model_class.replica_spec_name
      end
    end
  end
end
