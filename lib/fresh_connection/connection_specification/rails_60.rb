# frozen_string_literal: true

module FreshConnection
  class ConnectionSpecification
    module Rails60
      def spec
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(config_with_spec_name).spec(@spec_name.to_sym)
      end

      private

      def config_with_spec_name
        if defined?(ActiveRecord::DatabaseConfigurations)
          ActiveRecord::DatabaseConfigurations.new(@spec_name => build_config)
        else
          { @spec_name => build_config }
        end
      end

      def config_from_url
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(database_group_url).to_hash
      end

      def base_config
        ActiveRecord::Base.connection_pool.spec.config
      end
    end
  end
end

