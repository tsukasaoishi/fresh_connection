module FreshConnection
  class SlaveConnectionHandler
    def initialize
      @class_to_pool = {}
    end

    def establish_connection(name, slave_group)
      @class_to_pool[name] = FreshConnection.connection_manager.new
    end

    def connection(klass)
      detect_connection_manager(klass).slave_connection
    end

    def put_aside!
      @class_to_pool.values.each do |connection_manager|
        connection_manager.put_aside!
      end
    end

    def recovery(klass, failure_connection, exception)
      connection_manager = detect_connection_manager(klass)
      connection_manager.recovery(failure_connection, exception)
    end

    private

    def detect_connection_manager(klass)
      c = @class_to_pool[klass.name]
      return c if c
      return nil if ActiveRecord::Base == klass
      detect_connection_manager(klass.superclass)
    end
  end
end

