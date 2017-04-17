require "test_helper"

class ReplicaConnectionTest < Minitest::Test
  test "return DB Adapter object" do
    case ENV['DB_ADAPTER']
    when 'mysql2'
      assert_kind_of ActiveRecord::ConnectionAdapters::Mysql2Adapter, User.replica_connection
    when 'postgresql'
      assert_kind_of ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, User.replica_connection
    end
  end
end

