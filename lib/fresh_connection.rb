module FreshConnection
  autoload :ConnectionManager, 'fresh_connection/connection_manager'
  autoload :AbstractConnectionManager, 'fresh_connection/abstract_connection_manager'
  autoload :ConnectionManager, 'fresh_connection/connection_manager'
  autoload :ConnectionFactory, 'fresh_connection/connection_factory'
  autoload :SlaveConnectionHandler, 'fresh_connection/slave_connection_handler'
  autoload :AccessControl, 'fresh_connection/access_control'

  class << self
    attr_writer :connection_manager

    def connection_manager
      if defined?(@connection_manager)
        @connection_manager
      else
        ConnectionManager
      end
    end
  end
end

require 'fresh_connection/extend'
require 'fresh_connection/railtie' if defined?(Rails)
