module FreshConnection
  class AbstractConnectionManager
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

    def recovery(exception)
    end
    undef_method :recovery

    private

    def adapter_method
    end
    undef_method :adapter_method

    def slave_down_message?(message)
      slave_down_checker.down?(message)
    end

    def slave_down_checker
      @slave_down_checker ||= build_slave_down_checker
    end

    def build_slave_down_checker
      case adapter_method
      when /^mysql/
        require 'fresh_connection/slave_checker/mysql_slave_checker'
        MysqlSlaveChecker.new
      when /^postgresql/
        require 'fresh_connection/slave_checker/postgresql_slave_checker'
        PostgresqlSlaveChecker.new
      else
        require 'fresh_connection/slave_checker/nobody_slave_checker'
        NobodySlaveChecker.new
      end
    end
  end
end

