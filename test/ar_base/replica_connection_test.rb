require "test_helper"

class ReplicaConnectionTest < Minitest::Test
  test "return DB Adapter object" do
    adapter = ENV['DB_ADAPTER'] ||
      if ActiveRecord::Base.respond_to?(:connection_db_config)
        ActiveRecord::Base.connection_db_config.adapter
      elsif ActiveRecord::Base.respond_to?(:connection_config)
        ActiveRecord::Base.connection_config[:adapter]
      end

    case adapter.to_s
    when 'mysql2'
      assert_kind_of ActiveRecord::ConnectionAdapters::Mysql2Adapter, User.replica_connection
    when 'trilogy'
      assert_kind_of ActiveRecord::ConnectionAdapters::TrilogyAdapter, User.replica_connection
    when 'postgresql'
      assert_kind_of ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, User.replica_connection
    else
      flunk "Unexpected DB adapter: #{adapter.inspect}"
    end
  end
end
