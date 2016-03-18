module FreshConnection
  module SlaveDownChecker
    MYSQL_DOWN_MESSAGE = [
      "MySQL server has gone away",
      "closed MySQL connection",
      "Can't connect to local MySQL server"
    ]
    private_constant :MYSQL_DOWN_MESSAGE

    private

    def slave_server_down?(adapter_method, message)
      case adapter_method
      when /^mysql/
        mysql_down_message === message
      else
        false
      end
    end

    def mysql_down_message
      @mysql_down_message ||= Regexp.new(build_mysql_down_message, Regexp::IGNORECASE)
    end

    def build_mysql_down_message
      MYSQL_DOWN_MESSAGE.map{|msg| Regexp.escape(msg)}.join("|")
    end
  end
end
