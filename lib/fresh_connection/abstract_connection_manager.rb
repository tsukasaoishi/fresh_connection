module FreshConnection
  class AbstractConnectionManager
    EXCEPTION_MESSAGE_WHEN_SLAVE_SERVER_DOWN = [
      "MySQL server has gone away",
      "closed MySQL connection",
      "Can't connect to local MySQL server"
    ].map{|msg| Regexp.escape(msg)}.join("|")

    private_constant :EXCEPTION_MESSAGE_WHEN_SLAVE_SERVER_DOWN

    attr_reader :slave_group

    def initialize(slave_group = "slave")
      @slave_group = slave_group.to_s
      @slave_group = "slave" if @slave_group.empty?
    end

    def slave_connection
    end
    undef_method :slave_connection

    def clear_all_connections!
    end
    undef_method :clear_all_connections!

    def put_aside!
    end
    undef_method :put_aside!

    def recovery(failure_connection, exception)
    end
    undef_method :recovery

    private

    def slave_down_message?(message)
      /#{EXCEPTION_MESSAGE_WHEN_SLAVE_SERVER_DOWN}/o === message
    end
  end
end

