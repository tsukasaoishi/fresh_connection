# frozen_string_literal: true

module FreshConnection
  class AbstractConnectionManager
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
  end
end

