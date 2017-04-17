module FreshConnection
  class AbstractConnectionManager
    attr_reader :replica_group

    def initialize(replica_group = "replica")
      replica_group = "replica" if replica_group.to_s == "slave"
      @replica_group = replica_group.to_s
      @replica_group = "replica" if @replica_group.empty?
    end

    alias_method :slave_group, :replica_group

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

