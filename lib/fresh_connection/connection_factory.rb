require 'active_support/deprecation'
require 'active_support/core_ext/hash/keys'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'

module FreshConnection
  class ConnectionFactory
    def initialize(group, modify_spec = nil)
      @group = group.to_sym
      @modify_spec = modify_spec || {}.with_indifferent_access
      @spec = nil
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

    # when building a spec from envars, there may be no database.yml file, so
    # be careful to avoid implicit dependency on it or derived contents.

    def build_spec
      url = database_group_url(@group.to_s)
      if url
        build_group_spec_from_url(url)
      else
        build_spec_from_config
      end
    end

    def database_group_url(group)
      ENV['DATABASE_' + group.upcase + '_URL']
    end

    def build_group_spec_from_url(url)
      config = ar_spec.config.with_indifferent_access
      spec = build_spec_from_url(url)
      group_config = (config[@group] ||= {}.with_indifferent_access)
      config.merge(group_config).merge(spec).merge(@modify_spec)
    end

    def build_spec_from_url(url)
      ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(url).to_hash
    end

    def build_spec_from_config
      config = ar_spec.config.with_indifferent_access
      group_config = config[@group] || {}.with_indifferent_access

      if group_config.size == 0 && @group == :replica && config.key?(:slave)
        # provide backward-compatibility with :slave profile
        ActiveSupport::Deprecation.warn(
          "'slave' in database.yml is deprecated and will ignored from version 2.4.0. use 'replica' instead."
        )
        group_config = (config[:slave] || {}).with_indifferent_access
      end
      config.merge(group_config).merge(@modify_spec)
    end

    def ar_spec
      ActiveRecord::Base.connection_pool.spec
    end
  end
end
