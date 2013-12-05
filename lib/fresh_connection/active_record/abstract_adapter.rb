module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def select_all_with_slave_cluster(*args)
        Rails.logger.info "1111111111 : #{open_transactions}"
        if FreshConnection::SlaveConnection.slave_access?
          change_connection {select_all_without_slave_cluster(*args)}
        else
          select_all_without_slave_cluster(*args)
        end
      end
      alias_method_chain :select_all, :slave_cluster

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
