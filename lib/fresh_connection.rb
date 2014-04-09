require 'active_record'

module FreshConnection
  class << self
    def rails_3?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def rails_4?
      ActiveRecord::VERSION::MAJOR == 4
    end
  end
end

require "fresh_connection/version"
require "fresh_connection/connection_manager"
require "fresh_connection/access_control"
require "fresh_connection/rack/connection_management"
require "fresh_connection/railtie.rb"
