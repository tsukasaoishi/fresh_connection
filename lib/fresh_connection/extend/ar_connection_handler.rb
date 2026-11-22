# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArConnectionHandler
      if RUBY_VERSION >= "3.0"
        private def resolve_pool_config(*, **)
          pool_config = super
          __extend_adapter_for_pool_config(pool_config)
          pool_config
        end
      else
        private def resolve_pool_config(*args)
          pool_config = super(*args)
          __extend_adapter_for_pool_config(pool_config)
          pool_config
        end
        ruby2_keywords :resolve_pool_config if respond_to?(:ruby2_keywords, true)
      end

      private

      def __extend_adapter_for_pool_config(pool_config)
        db_config = pool_config.db_config
        adapter_name = db_config.adapter.to_s

        case adapter_name
        when "mysql", "mysql2"
          __load_adapter_class(db_config)
          require 'fresh_connection/extend/adapters/m2_adapter'
          if defined?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
            __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::Mysql2Adapter, M2Adapter)
          end
        when "trilogy"
          __load_adapter_class(db_config)
          require 'fresh_connection/extend/adapters/trilogy_adapter'
          if defined?(::ActiveRecord::ConnectionAdapters::TrilogyAdapter)
            __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::TrilogyAdapter, TrilogyAdapter)
          end
        when "postgresql", "postgis"
          __load_adapter_class(db_config)
          require 'fresh_connection/extend/adapters/pg_adapter'
          if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
            __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, PgAdapter)
          end
        end
      end

      def __load_adapter_class(db_config)
        db_config.adapter_class if db_config.respond_to?(:adapter_class)
      rescue LoadError, StandardError
        nil
      end

      def __extend_adapter_by_fc(klass, extend_adapter)
        return if klass.include?(extend_adapter)

        klass.prepend BaseAdapter
        klass.prepend extend_adapter
      end
    end
  end
end
