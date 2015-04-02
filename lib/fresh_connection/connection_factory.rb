module FreshConnection
  class ConnectionFactory
    def initialize(group)
      @group = group.to_sym
    end

    def new_connection
      ActiveRecord::Base.__send__(adapter_method, spec)
    end

    private

    def adapter_method
      @adapter_method ||= ar_spec.adapter_method
    end

    def spec
      @spec ||= build_spec
    end

    def build_spec
      config = ar_spec.config
      config.merge(config[@group] || {})
    end

    def ar_spec
      ActiveRecord::Base.connection_pool.spec
    end
  end
end
