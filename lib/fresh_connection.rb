require 'active_record'
require 'active_support/core_ext'
require 'active_support/dependencies/autoload'

module FreshConnection
  extend ActiveSupport::Autoload

  autoload :AccessControl
  autoload :ConnectionManager
  autoload :SlaveConnectionHandler
  autoload :Initializer
  autoload :SlaveConnection

  class << self
    attr_writer :connection_manager, :ignore_configure_connection, :retry_limit, :env

    def connection_manager
      @connection_manager || ConnectionManager
    end

    def ignore_configure_connection?
      !!@ignore_configure_connection
    end

    def retry_limit
      @retry_limit || 3
    end

    def env
      @env ||= defined?(Rails) && Rails.env
    end

    def rails_3?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def rails_4?
      ActiveRecord::VERSION::MAJOR == 4
    end
  end
end

require "fresh_connection/railtie.rb" if defined?(Rails)
