module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def select_all_with_slave_cluster(*args)
        if FreshConnection::SlaveConnection.slave_access?
          change_connection {select_all_without_slave_cluster(*args)}
        else
          select_all_without_slave_cluster(*args)
        end
      end
      alias_method_chain :select_all, :slave_cluster

      def columns_with_slave_cluster(*args)
        if FreshConnection::SlaveConnection.slave_access?
          change_connection {columns_without_slave_cluster(*args)}
        else
          columns_without_slave_cluster(*args)
        end
      end
      alias_method_chain :columns, :slave_cluster

      def log_info_with_slave_cluster(sql, name, ms)
        name = "[MASTER] " + (name || "SQL") if !FreshConnection::SlaveConnection.slave_access? && name != "CACHE"
        log_info_without_slave_cluster(sql, name, ms)
      end
      alias_method_chain :log_info, :slave_cluster

      private

      def change_connection
        master_con, @connection = @connection, FreshConnection::SlaveConnection.connection.raw_connection
        yield
      ensure
        @connection = master_con
      end
    end
  end
end
