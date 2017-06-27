require 'active_support/core_ext/hash/keys'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'

module FreshConnection
  class ConnectionSpecification
    def initialize(spec_name, modify_spec: nil)
      @spec_name = spec_name.to_s
      @modify_spec = modify_spec.with_indifferent_access if modify_spec
    end

    def spec
      resolver.spec(@spec_name.to_sym)
    end

    private

    def resolver
      ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(@spec_name => build_config)
    end

    # when building a spec from envars, there may be no database.yml file, so
    # be careful to avoid implicit dependency on it or derived contents.

    def build_config
      config = base_config.with_indifferent_access

      s_config = replica_config(config)
      config = config.merge(s_config) if s_config

      config = config.merge(@modify_spec) if defined?(@modify_spec)
      config
    end

    def replica_config(config)
      if database_group_url
        config_from_url
      else
        config[@spec_name]
      end
    end

    def config_from_url
      ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(database_group_url).to_hash
    end

    def base_config
      ActiveRecord::Base.connection_pool.spec.config
    end

    def database_group_url
      ENV["DATABASE_#{@spec_name.upcase}_URL"]
    end
  end
end
