if ActiveRecord::VERSION::MAJOR == 3
  require "fresh_connection/extend/ar_relation/for_rails3"
else
  require "fresh_connection/extend/ar_relation/for_rails4"
end

module FreshConnection
  module Extend
    module ArRelation
      def self.prepended(base)
        base.__send__(:prepend, ForRails)
      end

      def calculate(operation, column_name, options = {})
        @klass.manage_access(enable_slave_access) { super }
      end

      def exists?(*args)
        @klass.manage_access(enable_slave_access) { super }
      end

      def enable_slave_access
        connection.open_transactions == 0 && @read_from_master.nil?
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
