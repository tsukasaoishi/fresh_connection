# frozen_string_literal: true
require 'active_support'
require 'active_support/core_ext'

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
      if ActiveRecord::VERSION::MAJOR == 6
        config = ActiveRecord::DatabaseConfigurations.new(@spec_name => build_config)
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(config)
      else
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(@spec_name => build_config)
      end
    end

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
