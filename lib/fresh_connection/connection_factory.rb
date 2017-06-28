require 'active_support/deprecation'
require 'fresh_connection/connection_specification'

module FreshConnection
  class ConnectionFactory
    def initialize(group, modify_spec = nil)
      deprecation_warn
      @spec = FreshConnection::ConnectionSpecification.new(group, modify_spec: modify_spec)
    end

    def new_connection
      deprecation_warn
      ActiveRecord::Base.__send__(@spec.adapter_method, @spec.confg)
    end

    private

    def deprecation_warn
      ActiveSupport::Deprecation.warn(
        "`FreshConnection::ConnectionFactory` class is deprecated and will removed from version 2.5.0."
      )
    end
  end
end
