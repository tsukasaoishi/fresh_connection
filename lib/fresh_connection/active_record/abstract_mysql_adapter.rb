module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter < AbstractAdapter
      private

      def configure_connection_with_ignore
        configure_connection_without_ignore unless FreshConnection::SlaveConnection.ignore_configure_connection?
      end
      alias_method_chain :configure_connection, :ignore
    end
  end
end
