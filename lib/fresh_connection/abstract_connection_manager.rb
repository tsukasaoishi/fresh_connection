require 'active_support/deprecation'
require 'fresh_connection/deprecation'

module FreshConnection
  class AbstractConnectionManager
    class << self
      def method_added(name)
        return unless name == :slave_connection

        ActiveSupport::Deprecation.warn(
          "'slave_connection' has been deprecated. use 'replica_connection' instead."
        )
      end
    end

    attr_reader :spec_name

    def initialize(spec_name = nil)
      @spec_name = (spec_name || "replica").to_s
    end

    def replica_connection
      raise NotImplementedError
    end

    def put_aside!
      raise NotImplementedError
    end

    def clear_all_connections!
      raise NotImplementedError
    end

    def recovery?
      raise NotImplementedError
    end

    def replica_group
      FreshConnection::Deprecation.warn(replica_group: :spec_name)
      spec_name
    end

    def slave_group
      FreshConnection::Deprecation.warn(slave_group: :spec_name)
      spec_name
    end
  end
end

