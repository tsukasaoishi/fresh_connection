module FreshConnection
  class AbstractConnectionManager
    EXCEPTION_MESSAGE_WHEN_SLAVE_SERVER_DOWN = [
      "MySQL server has gone away",
      "closed MySQL connection",
      "Can't connect to local MySQL server"
    ].map{|msg| Regexp.escape(msg)}.join("|")

    def initialize
      @mutex = Mutex.new
    end

    def slave_connection
    end

    def put_aside!
    end

    def recovery(failure_connection, exception)
      false
    end

    def recoverable?
      false
    end

    private

    def synchronize
      @mutex.synchronize{ yield }
    end

    def current_thread_id
      Thread.current.object_id
    end

    def slave_down_message?(message)
      /#{EXCEPTION_MESSAGE_WHEN_SLAVE_SERVER_DOWN}/o =~ message
    end
  end
end

