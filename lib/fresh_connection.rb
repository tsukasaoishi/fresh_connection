require 'active_record'
require "fresh_connection/version"
require "fresh_connection/connection_manager"
require "fresh_connection/access_control"
require "fresh_connection/slave_connection_handler"

module FreshConnection
  class << self
    attr_writer :connection_manager, :ignore_configure_connection, :retry_limit

    def connection_manager
      @connection_manager || ConnectionManager
    end

    def ignore_configure_connection?
      !!@ignore_configure_connection
    end

    def retry_limit
      @retry_limit || 3
    end

    def rails_3?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def rails_4?
      ActiveRecord::VERSION::MAJOR == 4
    end
  end
end

require "fresh_connection/railtie.rb"
