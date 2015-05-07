module FreshConnection
  class AbstractConnectionManager
    EXCEPTION_MESSAGE_WHEN_SLAVE_SERVER_DOWN = [
      "MySQL server has gone away",
      "closed MySQL connection",
      "Can't connect to local MySQL server"
    ].map{|msg| Regexp.escape(msg)}.join("|")

    attr_reader :slave_group

    def initialize(slave_group = "slave")
      @mutex = Mutex.new
      @slave_group = (slave_group.presence || "slave").to_s
    end

    def slave_connection
    end
    undef_method :slave_connection

    def put_aside!
    end
    undef_method :put_aside!

    def recovery(failure_connection, exception)
    end
    undef_method :recovery

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

