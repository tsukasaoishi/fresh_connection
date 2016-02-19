require "fresh_connection/extend/ar_relation/for_rails#{ActiveRecord::VERSION::MAJOR}"

module FreshConnection
  module Extend
    module ArRelation
      def self.prepended(base)
        base.__send__(:prepend, ForRails)
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
