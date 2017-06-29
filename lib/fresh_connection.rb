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
  end
end

require 'fresh_connection/extend'

if defined?(Rails)
  if Rails::VERSION::MAJOR == "4"
    require 'fresh_connection/railtie_for_rails4'
  else
    require 'fresh_connection/railtie'
  end
end
