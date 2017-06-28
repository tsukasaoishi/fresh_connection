require 'concurrent'
require 'singleton'

module FreshConnection
  class ReplicaConnectionHandler
    include Singleton

    def initialize
      @owner_to_pool = Concurrent::Map.new(initial_capacity: 2) do |h, k|
        h[k] = Concurrent::Map.new(initial_capacity: 2)
      end
    end

    def establish_connection(spec_name)
      spec_name = spec_name.to_s
      remove_connection(spec_name)

      message_bus = ActiveSupport::Notifications.instrumenter
      payload = {
        connection_id: object_id,
        spec_name: spec_name
      }

      message_bus.instrument("!connection.active_record", payload) do
        owner_to_pool[spec_name] = FreshConnection.connection_manager.new(spec_name)
      end
    end

    def connection(spec_name)
      detect_connection_manager(spec_name).replica_connection
    end

    def clear_all_connections!
      all_connection_managers do |connection_manager|
        connection_manager.clear_all_connections!
      end
    end

    def recovery?(spec_name)
      detect_connection_manager(spec_name).recovery?
    end

    def put_aside!
      all_connection_managers do |connection_manager|
        connection_manager.put_aside!
      end
    end

    private

    def remove_connection(spec_name)
      pool = owner_to_pool.delete(spec_name.to_s)
      return unless pool

      pool.clear_all_connections!
    end

    def all_connection_managers
      owner_to_pool.each_value do |connection_manager|
        yield(connection_manager)
      end
    end

    def detect_connection_manager(spec_name)
      owner_to_pool[spec_name.to_s]
    end

    def owner_to_pool
      @owner_to_pool[Process.pid]
    end
  end
end

