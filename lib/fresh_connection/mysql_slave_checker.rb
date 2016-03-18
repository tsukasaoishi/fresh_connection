module FreshConnection
  class MysqlSlaveChecker
    MYSQL_DOWN_MESSAGE = [
      "MySQL server has gone away",
      "closed MySQL connection",
      "Can't connect to local MySQL server"
    ]
    private_constant :MYSQL_DOWN_MESSAGE

    def down?(message)
      down_message_regexp === message
    end

    private

    def down_message_regexp
      @mysql_down_message ||= Regexp.new(build_mysql_down_message, Regexp::IGNORECASE)
    end

    def build_mysql_down_message
      MYSQL_DOWN_MESSAGE.map{|msg| Regexp.escape(msg)}.join("|")
    end
  end
end
