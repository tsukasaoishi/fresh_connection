require 'active_support/core_ext/hash/keys'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'

module FreshConnection
  class ConnectionFactory
    def initialize(spec_name, modify_spec = nil)
      @spec_name = spec_name.to_s
      @modify_spec = (modify_spec || {}).with_indifferent_access
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
      url = database_group_url
      if url
        build_group_spec_from_url(url)
      else
        build_spec_from_config
      end
    end

    def database_group_url
      ENV['DATABASE_' + @spec_name.upcase + '_URL']
    end

    def build_group_spec_from_url(url)
      config = ar_spec.config.with_indifferent_access
      spec = build_spec_from_url(url)
      group_config = (config[@spec_name] ||= {}.with_indifferent_access)
      config.merge(group_config).merge(spec).merge(@modify_spec)
    end

    def build_spec_from_url(url)
      ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(url).to_hash
    end

    def build_spec_from_config
      config = ar_spec.config.with_indifferent_access
      group_config = (config[@spec_name] || {}).with_indifferent_access

      config.merge(group_config).merge(@modify_spec)
    end

    def ar_spec
      ActiveRecord::Base.connection_pool.spec
    end
  end
end
