# frozen_string_literal: true

module FreshConnection
  class << self
    def connection_manager
      if defined?(@connection_manager)
        @connection_manager
      else
        require 'fresh_connection/connection_manager'
        ConnectionManager
      end
    end

    def connection_manager=(mgr)
      FreshConnection::ReplicaConnectionHandler.instance.refresh_all
      @connection_manager = mgr
    end

    def rails_52?
      [ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR] == [5, 2]
    end
  end
end

require 'fresh_connection/replica_connection_handler'
require 'fresh_connection/abstract_connection_manager'
require 'fresh_connection/connection_specification'
require 'fresh_connection/extend'
require 'fresh_connection/railtie' if defined?(Rails)
