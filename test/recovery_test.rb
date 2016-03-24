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
          c = super
          c.disconnect!
          raise ActiveRecord::StatementInvalid, "something error message"
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
