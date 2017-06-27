module FreshConnection
  module Extend
    module ArAbstractAdapter
      def self.prepended(base)
        base.send :attr_writer, :replica_group
        base.send :attr_accessor, :master_connection
      end

      def log(*args)
        args[1] = "[#{@replica_group}] #{args[1]}" if defined?(@replica_group)
        super
      end

      def query_cache
        return @query_cache unless master_connection
        master_connection.query_cache
      end

      def query_cache_enabled
        return @query_cache_enabled unless master_connection
        master_connection.query_cache_enabled
      end

      def cache(&block)
        return super unless master_connection
        master_connection.cache(&block)
      end

      def enable_query_cache!
        return super unless master_connection
        master_connection.enable_query_cache!
      end

      def disable_query_cache!
        return super unless master_connection
        master_connection.disable_query_cache!
      end

      def uncached(&block)
        return super unless master_connection
        master_connection.uncached(&block)
      end

      def clear_query_cache
        return super unless master_connection
        master_conection.clear_query_cache
      end

      def select_all(*args)
        return super unless master_connection
        @query_cache_enabled = master_connection.query_cache_enabled
        super
      end

      private

      def cache_sql(*args)
        return super unless master_connection
        @query_cache = master_connection.query_cache
        super
      end
    end
  end
end
