module FreshConnection
  class AbstractConnectionManager
    attr_reader :spec_name

    def initialize(spec_name = "replica")
      @spec_name = spec_name.to_s
      @spec_name = "replica" if @spec_name.empty?
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

