# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArResolver
      def spec(*args)
        specification = super

        case specification.config[:adapter].to_s
        when "mysql", "mysql2"
          require 'fresh_connection/extend/adapters/m2_adapter'
          __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::Mysql2Adapter, M2Adapter)
        when "postgresql"
          require 'fresh_connection/extend/adapters/pg_adapter'
          __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, PgAdapter)
        else
          require 'fresh_connection/extend/adapters/other_adapter_proxy'
          base_adapter_name = "#{specification.config[:adapter].to_s}_adapter".camelize
          __extend_adapter_by_fc(
            "::ActiveRecord::ConnectionAdapters::#{base_adapter_name}".constantize,
            OtherAdapterProxy
          )
        end

        specification
      end

      def __extend_adapter_by_fc(klass, extend_adapter)
        return if klass.include?(extend_adapter)
        klass.prepend BaseAdapter
        klass.prepend extend_adapter
      end
    end
  end
end
