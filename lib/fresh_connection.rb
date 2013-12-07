require "fresh_connection/version"
require "fresh_connection/slave_connection"
require "fresh_connection/rack/connection_management"
require "fresh_connection/active_record/relation"
require "fresh_connection/active_record/abstract_adapter"
require "fresh_connection/active_record/mysql2_adapter"

require "fresh_connection/railtie.rb" if defined?(Rails)
