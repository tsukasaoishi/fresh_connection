module FreshConnection
  class AbstractConnectionManager
    def initialize
      @mutex = Mutex.new
    end

    def slave_connection
    end

    def put_aside!
    end

    def recoverable?
      false
    end

    def recovery(failure_connection, exception)
    end

    private

    def synchronize
      @mutex.synchronize{ yield }
    end

    def current_thread_id
      Thread.current.object_id
    end
  end
end

