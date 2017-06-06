require 'concurrent'

module FreshConnection

  class ReplicaConnectionHandler

    cattr_accessor :replica_query_cache_sync

    def self.enable_query_cache_sync!
      @@replica_query_cache_sync = true
    end

    def self.disable_query_cache_sync!
      @@replica_query_cache_sync = false
    end

    def initialize
      @replica_group_to_pool = Concurrent::Map.new
      @class_to_pool = Concurrent::Map.new
    end

    def establish_connection(name, replica_group)
      if cm = @class_to_pool[name]
        cm.put_aside!
        @class_to_pool.delete(name)
      end

      @replica_group_to_pool[name] = replica_group
    end

    def connection(klass)
      detect_connection_manager(klass).replica_connection
    end

    def clear_all_connections!
      all_connection_managers do |connection_manager|
        connection_manager.clear_all_connections!
      end
    end

    def clear_all_query_caches!
      all_connection_managers do |connection_manager|
        connection_manager.clear_replica_query_caches!
      end
    end

    def recovery?(klass)
      detect_connection_manager(klass).recovery?
    end

    def put_aside!
      all_connection_managers do |connection_manager|
        connection_manager.put_aside!
      end
    end

    def replica_group(klass)
      detect_connection_manager(klass).replica_group
    end

    private

    def all_connection_managers
      @class_to_pool.each_value do |connection_manager|
        yield(connection_manager)
      end
    end

    def detect_connection_manager(klass)
      c = class_to_pool(klass.name)
      return c if c
      return nil if ActiveRecord::Base == klass
      detect_connection_manager(klass.superclass)
    end

    def class_to_pool(name)
      return @class_to_pool[name] if @class_to_pool.key?(name)
      g = @replica_group_to_pool[name]
      return nil unless g
      @class_to_pool[name] = FreshConnection.connection_manager.new(g)
    end
  end
end

