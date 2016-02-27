require 'concurrent'

module FreshConnection
  class SlaveConnectionHandler
    def initialize
      @class_to_pool = Concurrent::Map.new(initial_capacity: 2) do |h,k|
        h[k] = Concurrent::Map.new
      end
    end

    def establish_connection(name, slave_group)
      if cm = class_to_pool[name]
        cm.put_aside!
      end

      class_to_pool[name] = FreshConnection.connection_manager.new(slave_group)
    end

    def connection(klass)
      detect_connection_manager(klass).slave_connection
    end

    def clear_all_connections!
      all_connection_managers do |connection_manager|
        connection_manager.clear_all_connections!
      end
    end

    def put_aside!
      all_connection_managers do |connection_manager|
        connection_manager.put_aside!
      end
    end

    def recovery(klass, failure_connection, exception)
      detect_connection_manager(klass).recovery(failure_connection, exception)
    end

    def slave_group(klass)
      detect_connection_manager(klass).slave_group
    end

    private

    def all_connection_managers
      class_to_pool.values.each do |connection_manager|
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
      @class_to_pool[Process.pid]
    end
  end
end

