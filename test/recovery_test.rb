require "test_helper"

class RecoveryTest < Minitest::Test
  class User3 < ActiveRecord::Base
    self.table_name = "users"

    class << self
      attr_writer :limit_time, :access_time, :disconnect

      def replica_connection
        return super unless defined?(@access_time)

        @access_time += 1
        if @access_time > @limit_time
          super
        else
          if @disconnect
            c = super
            c.disconnect!
          end
          raise ActiveRecord::StatementInvalid, "something error message"
        end
      end
    end
  end

  test "enable recovery" do
    User3.disconnect = true
    User3.access_time = 0
    User3.limit_time = 1

    assert User3.take
  end

  test "raise exception when retry over" do
    User3.disconnect = true
    User3.access_time = 0
    User3.limit_time = 100

    assert_raises(ActiveRecord::StatementInvalid) do
      User3.first
    end
  end

  test "raise exception when conection active" do
    User3.disconnect = false
    User3.access_time = 0
    User3.limit_time = 1

    assert_raises(ActiveRecord::StatementInvalid) do
      User3.first
    end
  end
end
