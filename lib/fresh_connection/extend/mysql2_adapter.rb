module FreshConnection
  module Extend
    module Mysql2Adapter
      RETRY_LIMIT = 3
      private_constant :RETRY_LIMIT

      def self.prepended(base)
        base.__send__(:attr_writer, :model_class)
      end

      if ActiveRecord::VERSION::MAJOR == 5
        def select_all(arel, name = nil, binds = [], preparable: nil)
          check_and_change_connection(name) do |tagged_name|
            super(arel, tagged_name, binds, preparable: preparable)
          end
        end

        def select_rows(sql, name = nil, binds = [])
          check_and_change_connection(name) do |tagged_name|
            super(sql, tagged_name, binds)
          end
        end
      else
        def select_all(arel, name = nil, binds = [])
          check_and_change_connection(name) do |tagged_name|
            super(arel, tagged_name, binds)
          end
        end
      end

      private

      def check_and_change_connection(name, &block)
        if FreshConnection::AccessControl.slave_access?
          change_connection do
            block.call("[#{@model_class.slave_group}] #{name}")
          end
        else
          block.call(name)
        end
      end

      def change_connection
        retry_count = 0
        master_connection = @connection
        begin
          slave_connection = @model_class.slave_connection
          @connection = slave_connection.raw_connection
          yield
        rescue ActiveRecord::StatementInvalid => exception
          if @model_class.slave_connection_recovery(slave_connection, exception)
            retry_count += 1
            retry if retry_count < RETRY_LIMIT
          end

          raise
        end
      ensure
        @connection = master_connection
      end
    end
  end
end
