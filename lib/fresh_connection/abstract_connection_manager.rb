require 'active_support/deprecation'

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

    attr_reader :replica_group

    def initialize(replica_group = "replica")
      replica_group = "replica" if replica_group.to_s == "slave"
      @replica_group = replica_group.to_s
      @replica_group = "replica" if @replica_group.empty?
    end

    def slave_group
      ActiveSupport::Deprecation.warn(
        "'slave_group' is deprecated and will removed from version 2.4.0. use 'replica_group' instead."
      )

      replica_group
    end

    def replica_connection
    end
    undef_method :replica_connection

    def clear_all_connections!
    end
    undef_method :clear_all_connections!

    def put_aside!
    end
    undef_method :put_aside!

    def recovery?
    end
    undef_method :recovery?
  end
end

