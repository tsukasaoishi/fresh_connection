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

      private

      def exec_queries_with_fresh_connection
        return @records if loaded?

        FreshConnection::SlaveConnection.manage_access(@klass, go_slave?) do
          exec_queries_without_fresh_connection
        end
      end

      module ForRails4
        private
        def go_slave?
          connection.open_transactions == 0 && (readonly_value.nil? || readonly_value)
        end
      end

      module ForRails3
        private
        def go_slave?
          connection.open_transactions == 0 && (@readonly_value.nil? || @readonly_value)
        end
      end
    end
  end
end
