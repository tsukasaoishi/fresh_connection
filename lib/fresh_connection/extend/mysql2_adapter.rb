module FreshConnection
  module Extend
    module Mysql2Adapter
      def self.included(base)
        base.__send__(:attr_writer, :model_class)
      end

      def select_all(arel, name = nil, binds = [])
        if FreshConnection::AccessControl.slave_access?
          change_connection do
            super(arel, "[#{@model_class.slave_group}] #{name}", binds)
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
    end
  end
end
