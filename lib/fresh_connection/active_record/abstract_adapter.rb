module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def select_all_with_slave_cluster(arel, name = nil, binds = [])
        if FreshConnection::SlaveConnection.slave_access?
          change_connection {select_all_without_slave_connection(arel, "[slave] #{name}", binds)}
        else
          select_all_without_slave_connection(arel, name, binds)
        end
      end
      alias_method_chain :select_all, :slave_connection

      private

      def change_connection
        master_con, @connection =
          @connection, FreshConnection::SlaveConnection.connection.raw_connection
        yield
      ensure
        @connection = master_con
      end
    end
  end
end
