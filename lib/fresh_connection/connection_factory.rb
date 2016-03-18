module FreshConnection
  class ConnectionFactory
    def initialize(group, modify_spec = {})
      @group = group.to_sym
      @modify_spec = modify_spec
    end

    def new_connection
      ActiveRecord::Base.__send__(adapter_method, spec)
    end

    def adapter_method
      @adapter_method ||= ar_spec.adapter_method
    end

    private

    def spec
      @spec ||= build_spec
    end

    def build_spec
      config = ar_spec.config
      config.merge(config[@group] || {}).merge(@modify_spec)
    end

    def ar_spec
      ActiveRecord::Base.connection_pool.spec
    end
  end
end
