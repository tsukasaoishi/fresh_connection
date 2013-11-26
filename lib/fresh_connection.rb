require "fresh_connection/slave_connection"
require "fresh_connection/rack/connection_management"
require "fresh_connection/active_record/base"
require "fresh_connection/active_record/connection_adapter"
require "fresh_connection/active_record/mysql_adapter"

require "fresh_connection/railtie.rb" if defined?(Rails)
