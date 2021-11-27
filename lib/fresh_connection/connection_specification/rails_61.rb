# frozen_string_literal: true

module FreshConnection
  class ConnectionSpecification
    module Rails61
      def spec
        db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(@spec_name.to_sym, ActiveRecord::Base.connection_pool.db_config.name, build_config)
        ActiveRecord::ConnectionAdapters::PoolConfig.new(ActiveRecord::Base, db_config)
      end

      private

      def config_from_url
        ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(database_group_url).to_hash
      end

      def base_config
        ActiveRecord::Base.connection_pool.db_config.configuration_hash
      end
    end
  end
end
