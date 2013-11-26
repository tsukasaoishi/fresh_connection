module ActiveRecord
  class MysqlAdapter < AbstractAdapter
    private

    def configure_connection_with_ignore
     configure_connection_without_ignore unless FreshConnection::SlaveConnection.ignore_configure_connection?
    end
  end
end

