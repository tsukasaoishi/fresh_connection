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
    attr_writer :connection_manager, :retry_limit, :env

    def connection_manager
      manager_klass = @connection_manager || rails_config(:connection_manager) || ConnectionManager
      manager_klass.is_a?(String) ? manager_klass.constantize : manager_klass
    end

    def retry_limit
      @retry_limit || rails_config(:retry_limit) || 3
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

    private

    def rails_config(target)
      return nil unless defined?(Rails)
      Rails.application.config.fresh_connection[target]
    end
  end
end

require "fresh_connection/railtie.rb" if defined?(Rails)
