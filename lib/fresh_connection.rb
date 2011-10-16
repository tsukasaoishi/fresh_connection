module FreshConnection
  VERSION = "0.0.1"
end

require "fresh_connection/slave_connection"
require "fresh_connection/rack/connection_management"

Dir.glob("#{File.join(File.dirname(__FILE__), "../rails/initializers")}/*.rb").each{|path| require path}
