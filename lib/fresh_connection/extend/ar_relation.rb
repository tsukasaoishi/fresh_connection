require 'active_support/deprecation'
require "fresh_connection/extend/ar_relation/for_rails#{ActiveRecord::VERSION::MAJOR}"

module FreshConnection
  module Extend
    module ArRelation
      def self.prepended(base)
        base.__send__(:prepend, ForRails)
      end

      def calculate(operation, column_name, options = {})
        if options[:readonly] == false
          ActiveSupport::Deprecation.warn(":readonly key has been deprecated.", caller)
        end

        slave_access = enable_slave_access && options[:readonly] != false
        @klass.manage_access(slave_access) { super }
      end

      def enable_slave_access
        connection.open_transactions == 0 && @read_from_master.nil?
      end

      def readonly(value = true)
        if value == false
          ActiveSupport::Deprecation.warn("readonly(false) has been deprecated. Use read_master instead", caller)
          read_master
        else
          super
        end
      end

      private

      def exec_queries
        return @records if loaded?

        @klass.manage_access(enable_slave_access) do
          super
        end
      end
    end
  end
end
