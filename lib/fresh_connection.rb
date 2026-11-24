# frozen_string_literal: true

require 'fresh_connection/version'
require 'fresh_connection/deprecator'
require 'fresh_connection/rails_replica'

module FreshConnection
  DEFAULT_RETRY_LIMIT = 3

  class << self
    def configure
      yield self
    end

    def put_aside
      defined?(@put_aside) ? @put_aside : true
    end

    def put_aside=(value)
      @put_aside = !!value
    end

    def recovery
      defined?(@recovery) ? @recovery : true
    end

    def recovery=(value)
      @recovery = !!value
    end

    def retry_limit
      defined?(@retry_limit) ? @retry_limit : DEFAULT_RETRY_LIMIT
    end

    def retry_limit=(value)
      @retry_limit = [value ? value.to_i : 0, 0].max
    end

    def connection_manager
      if defined?(@connection_manager) && @connection_manager
        @connection_manager
      else
        require 'fresh_connection/connection_manager'
        ConnectionManager
      end
    end

    def connection_manager=(mgr)
      if mgr
        FreshConnection.deprecator.warn(
          "FreshConnection.connection_manager= is deprecated and will be removed in FreshConnection 3.2.0. " \
          "Please use Rails' native `connects_to` connection pool management instead."
        )
      end
      FreshConnection::ReplicaConnectionHandler.instance.refresh_all
      @connection_manager = mgr
    end

    def custom_connection_manager?
      defined?(@connection_manager) && !@connection_manager.nil?
    end
  end
end

require 'fresh_connection/replica_connection_handler'
require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_specification'
require 'fresh_connection/extend'
require 'fresh_connection/railtie' if defined?(Rails::Railtie)
