# frozen_string_literal: true
require 'fresh_connection/connection_manager'

module FreshConnection
  class << self
    attr_writer :connection_manager

    def connection_manager
      if defined?(@connection_manager)
        @connection_manager
      else
        ConnectionManager
      end
    end

    def rails_52?
      [ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR] == [5, 2]
    end
  end
end

require 'fresh_connection/extend'
require 'fresh_connection/railtie' if defined?(Rails)
