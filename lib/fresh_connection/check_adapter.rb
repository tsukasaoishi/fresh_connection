# frozen_string_literal: true

module FreshConnection
  module CheckAdapter
    class << self
      def check(klass)
        if mysql?(klass)
          :mysql
        elsif postgresql?(klass)
          :postgresql
        end
      end

      def mysql?(klass)
        if defined?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
          klass == ::ActiveRecord::ConnectionAdapters::Mysql2Adapter
        else
          false
        end
      end

      def postgresql?(klass)
        if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          klass == ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
        else
          false
        end
      end
    end
  end
end
