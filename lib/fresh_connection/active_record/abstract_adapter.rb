module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def select_all_with_slave_connection(arel, name = nil, binds = [])
        if FreshConnection::SlaveConnection.slave_access?
          change_connection {select_all_without_slave_connection(arel, "[slave] #{name}", binds)}
        else
          select_all_without_slave_connection(arel, name, binds)
        end
      end
      alias_method_chain :select_all, :slave_connection

      private

      def change_connection
        master_connection, @connection =
          @connection, FreshConnection::SlaveConnection.raw_connection
        yield
      ensure
        @connection = master_connection
      end
    end
  end
end
