module FreshConnection
  module Extend
    module ArRelation
      def self.included(base)
        base.alias_method_chain :exec_queries, :fresh_connection

        if FreshConnection.rails_4?
          base.__send__(:include, ForRails4)
        elsif FreshConnection.rails_3?
          base.__send__(:include, ForRails3)
        end
      end

      def calculate(operation, column_name, options = {})
        slave_access = enable_slave_access && options[:readonly] != false
        @klass.manage_access(slave_access) { super }
      end

      def pluck(*args)
        return super unless enable_slave_access

        begin
          origin_c = klass.connection.raw_connection
          klass.connection.instance_variable_set("@connection", klass.slave_connection.raw_connection)
          super
        ensure
          klass.connection.instance_variable_set("@connection", origin_c)
        end
      end

      private

      def exec_queries_with_fresh_connection
        return @records if loaded?

        @klass.manage_access(enable_slave_access) do
          exec_queries_without_fresh_connection
        end
      end

      module ForRails4
        private
        def enable_slave_access
          connection.open_transactions == 0 && (readonly_value.nil? || readonly_value)
        end
      end

      module ForRails3
        private
        def enable_slave_access
          connection.open_transactions == 0 && (@readonly_value.nil? || @readonly_value)
        end
      end
    end
  end
end
