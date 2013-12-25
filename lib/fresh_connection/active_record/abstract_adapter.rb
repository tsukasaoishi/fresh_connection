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
        retry_count = 0
        master_connection = @connection
        begin
          slave_connection = FreshConnection::SlaveConnection.slave_connection
          @connection = slave_connection.raw_connection
          yield
        rescue ActiveRecord::StatementInvalid => exception
          if FreshConnection::SlaveConnection.recovery(slave_connection, exception)
            retry_count += 1
            retry if retry_count < FreshConnection::SlaveConnection.retry_limit
          end

          raise
        end
      ensure
        @connection = master_connection
      end
    end
  end
end
