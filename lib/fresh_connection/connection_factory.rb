require 'active_support/deprecation'
require 'active_support/core_ext/hash/keys'

module FreshConnection
  class ConnectionFactory
    def initialize(group, modify_spec = {})
      @group = group.to_sym
      @modify_spec = modify_spec.symbolize_keys
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
      config = ar_spec.config.symbolize_keys
      group_config = config[@group]

      # provide backward compatibility for older :slave usage
      if !group_config && @group == :replica && config.key?(:slave)
        ActiveSupport::Deprecation.warn(
          "'slave' in database.yml is deprecated and will ignored from version 2.4.0. use 'replica' insted."
        )
        group_config = config[:slave]
      end

      group_config = (group_config || {}).symbolize_keys

      config.merge(group_config).merge(@modify_spec)
    end

    def ar_spec
      ActiveRecord::Base.connection_pool.spec
    end
  end
end
