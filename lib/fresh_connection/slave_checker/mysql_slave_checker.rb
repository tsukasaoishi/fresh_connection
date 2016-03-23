module FreshConnection
  class MysqlSlaveChecker
    DOWN_MESSAGE = [
      "MySQL server has gone away",
      "closed MySQL connection",
      "Can't connect to local MySQL server"
    ]
    private_constant :DOWN_MESSAGE

    def down?(message)
      down_message_regexp === message
    end

    private

    def down_message_regexp
      @mysql_down_message ||= Regexp.new(build_mysql_down_message, Regexp::IGNORECASE)
    end

    def build_mysql_down_message
      DOWN_MESSAGE.map{|msg| Regexp.escape(msg)}.join("|")
    end
  end
end
