require 'concurrent'

module FreshConnection
  class ReplicaConnectionHandler
    def initialize
      @class_to_pool = Concurrent::Map.new
    end

    def establish_connection(name, replica_group)
      if cm = class_to_pool[name]
        cm.put_aside!
      end

      class_to_pool[name] = FreshConnection.connection_manager.new(replica_group)
    end

    def connection(klass)
      detect_connection_manager(klass).replica_connection
    end

    def clear_all_connections!
      all_connection_managers do |connection_manager|
        connection_manager.clear_all_connections!
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
      class_to_pool.each_value do |connection_manager|
        yield(connection_manager)
      end
    end

    def detect_connection_manager(klass)
      c = class_to_pool[klass.name]
      return c if c
      return nil if ActiveRecord::Base == klass
      detect_connection_manager(klass.superclass)
    end

    def class_to_pool
      @class_to_pool
    end
  end
end

