require 'active_support/dependencies/autoload'

module FreshConnection
  extend ActiveSupport::Autoload

  autoload :ConnectionManager
  autoload :Rack
  autoload :AbstractConnectionManager
  autoload :ConnectionManager
  autoload :ConnectionFactory
  autoload :SlaveConnectionHandler
  autoload :AccessControl

  module Extend
    extend ActiveSupport::Autoload

    autoload :ArBase
    autoload :ArRelation
    autoload :ConnectionHandler
    autoload :Mysql2Adapter
    autoload :ArStatementCache
  end

  autoload_under 'rack' do
    autoload :ConnectionManagement
  end

  class << self
    attr_writer :connection_manager

    def connection_manager
      @connection_manager || ConnectionManager
    end
  end
end

require 'fresh_connection/extend'
require 'fresh_connection/railtie' if defined?(Rails)
