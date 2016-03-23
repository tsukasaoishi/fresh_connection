require "test_helper"

class SlaveConnectionTest < Minitest::Test
  test "return DB Adapter object" do
    case ENV['DB_ADAPTER']
    when 'mysql2'
      assert_kind_of ActiveRecord::ConnectionAdapters::Mysql2Adapter, User.slave_connection
    when 'postgresql'
      assert_kind_of ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, User.slave_connection
    end
  end
end

