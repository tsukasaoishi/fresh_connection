require 'fresh_connection/connection_manager'

module FreshConnection
  class << self
    attr_writer :connection_manager

    def connection_manager
      @connection_manager || ConnectionManager
    end
  end
end

require 'fresh_connection/extend'
require "fresh_connection/railtie" if defined?(Rails)
