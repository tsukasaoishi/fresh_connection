module FreshConnection
  module Extend
    module Mysql2Adapter
      def self.included(base)
        base.alias_method_chain :configure_connection, :fresh_connection
      end

      def select_all(arel, name = nil, binds = [])
        if FreshConnection::AccessControl.slave_access?
          change_connection do
            super(arel, "[slave] #{name}", binds)
          end
        else
          super
        end
      end

      private

      def change_connection
        retry_count = 0
        master_connection = @connection
        begin
          slave_connection = FreshConnection::AccessControl.slave_connection
          @connection = slave_connection.raw_connection
          yield
        rescue ActiveRecord::StatementInvalid => exception
          if FreshConnection::AccessControl.recovery(slave_connection, exception)
            retry_count += 1
            retry if retry_count < FreshConnection::AccessControl.retry_limit
          end

          raise
        end
      ensure
        @connection = master_connection
      end

      def configure_connection_with_fresh_connection
        return if FreshConnection.ignore_configure_connection?
        configure_connection_without_fresh_connection
      end
    end
  end
end
