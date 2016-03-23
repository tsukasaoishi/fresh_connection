module FreshConnection
  class PostgresqlSlaveChecker
    DOWN_MESSAGE = []
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
