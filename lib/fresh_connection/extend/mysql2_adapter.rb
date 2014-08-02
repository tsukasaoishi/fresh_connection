module FreshConnection
  module Extend
    module Mysql2Adapter
      def self.included(base)
        base.__send__(:attr_writer, :model_class)
        base.alias_method_chain :configure_connection, :fresh_connection
        base.alias_method_chain :execute, :fresh_connection
      end

      def execute_with_fresh_connection(sql, name = nil)
        if @model_class && FreshConnection::AccessControl.slave_access?
          change_connection do
            execute_without_fresh_connection(sql, "[#{@model_class.slave_group}] #{name}")
          end
        else
          execute_without_fresh_connection(sql, name)
        end
      end

      private

      def change_connection
        retry_count = 0
        master_connection = @connection
        begin
          slave_connection = @model_class.slave_connection
          @connection = slave_connection.raw_connection
          yield
        rescue ActiveRecord::StatementInvalid => exception
          if @model_class.recovery(slave_connection, exception)
            retry_count += 1
            retry if retry_count < FreshConnection.retry_limit
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
