module ActiveRecord
  class Relation
    private

    def exec_queries_with_slave_connection
      return @records if loaded?

      if go_slave?
        FreshConnection::SlaveConnection.slave_access { exec_queries_without_slave_connection }
      else
        FreshConnection::SlaveConnection.master_access { exec_queries_without_slave_connection }
      end
    end
    alias_method_chain :exec_queries, :slave_connection

    def go_slave?
      !FreshConnection::SlaveConnection.ignore_model?(@klass.name) &&
        connection.open_transactions == 0 && (@readonly_value.nil? || @readonly_value)
    end
  end
end
