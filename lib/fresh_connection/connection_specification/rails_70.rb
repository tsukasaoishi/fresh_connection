# frozen_string_literal: true

module FreshConnection
  class ConnectionSpecification
    module Rails70
      def spec
        db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
          @spec_name.to_s,
          base_db_config_name,
          build_config
        )

        pool_config_klass = ActiveRecord::ConnectionAdapters::PoolConfig
        if pool_config_klass.instance_method(:initialize).arity == 2
          pool_config_klass.new(ActiveRecord::Base, db_config)
        else
          role = ActiveRecord.respond_to?(:reading_role) ? ActiveRecord.reading_role : :reading
          shard = ActiveRecord::Base.respond_to?(:default_shard) ? ActiveRecord::Base.default_shard : :default
          pool_config_klass.new(ActiveRecord::Base, db_config, role, shard)
        end
      end

      private

      def config_from_url
        ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(database_group_url).to_hash
      end

      def base_config
        base_db_config.configuration_hash
      end

      def base_db_config
        if ActiveRecord::Base.respond_to?(:connection_db_config)
          ActiveRecord::Base.connection_db_config
        else
          ActiveRecord::Base.connection_pool.db_config
        end
      end

      def base_db_config_name
        base_db_config.name
      rescue ActiveRecord::ConnectionNotEstablished
        @spec_name.to_s
      end
    end
  end
end
