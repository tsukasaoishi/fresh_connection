module FreshConnection
  class AbstractConnectionManager
    attr_reader :spec_name

    def initialize(spec_name = "replica")
      @spec_name = spec_name.to_s
      @spec_name = "replica" if @spec_name.empty?
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
  end
end

