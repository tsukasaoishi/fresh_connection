require "test_helper"

class RecoveryTest < Minitest::Test
  class User3 < ActiveRecord::Base
    self.table_name = "users"

    class << self
      attr_writer :limit_time

      def slave_connection
        @access_time ||= 0
        @access_time += 1
        if @access_time > limit_time
          super
        else
          case ENV['DB_ADAPTER']
          when 'mysql2'
            raise ActiveRecord::StatementInvalid, "MySQL server has gone away"
          when 'postgresql'
            raise ActiveRecord::StatementInvalid, ""
          end
        end
      end

      def limit_time
        @limit_time || 1
      end
    end
  end

  test "enable recovery" do
    User3.limit_time = 1
    assert User3.first
  end

  test "raise exception when retry over" do
    User3.limit_time = 100
    assert_raises(ActiveRecord::StatementInvalid) do
      User3.first
    end
  end
end
