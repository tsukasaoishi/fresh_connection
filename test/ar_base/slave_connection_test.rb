require "test_helper"

class SlaveConnectionTest < Minitest::Test
  test "return Mysql2Adapter object" do
    assert_kind_of ActiveRecord::ConnectionAdapters::Mysql2Adapter, User.slave_connection
  end
end

