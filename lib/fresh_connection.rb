require 'active_record'
require 'fresh_connection/access_control'
require 'fresh_connection/connection_manager'
require 'fresh_connection/slave_connection_handler'

module FreshConnection
  extend ActiveSupport::Autoload

  autoload :ConnectionManager
  autoload :SlaveConnectionHandler

  class << self
    attr_writer :connection_manager, :env

    def connection_manager
      @connection_manager || ConnectionManager
    end

    def env
      @env || defined?(Rails) && Rails.env
    end

    def rails_3?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def rails_4?
      ActiveRecord::VERSION::MAJOR == 4
    end
  end
end

require 'fresh_connection/extend'
require "fresh_connection/railtie.rb" if defined?(Rails)
