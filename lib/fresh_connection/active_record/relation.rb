module ActiveRecord
  class Relation
    private

    def exec_queries_with_slave_connection
      return @records if loaded?

      FreshConnection::SlaveConnection.manage_access(@klass.name, go_slave?) do
        exec_queries_without_slave_connection
      end
    end
    alias_method_chain :exec_queries, :slave_connection

    if Rails.version.to_f > 3
      def go_slave?
        connection.open_transactions == 0 && (readonly_value.nil? || readonly_value)
      end
    else
      def go_slave?
        connection.open_transactions == 0 && (@readonly_value.nil? || @readonly_value)
      end
    end
  end
end
