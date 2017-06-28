require "test_helper"

class DatabaseReplicaUrlTest < Minitest::Test
  test "use standard config/database.yml spec when DATABASE_REPLICA_URL is not defined" do
    test_config = { host: 'test_host', database: 'test_db', adapter: "mysql2" }

    ENV.stub :[], nil, 'DATABASE_REPLICA_URL'  do
      s = FreshConnection::ConnectionSpecification.new(:replica)
      s.stub(:base_config, { replica: test_config }) do
        config = s.spec.config

        assert_equal test_config[:host], config[:host]
        assert_equal test_config[:database], config[:database]
        assert_equal test_config[:adapter], config[:adapter]
        assert_nil config[:username]
        assert_nil config[:password]
      end
    end
  end

  test "use url components when DATABASE_REPLICA_URL is defined" do
    test_config = {
      host: "localhost",
      database: "procore_test_db",
      username: "procore_db",
      adapter: "postgresql",
      password: "SECRETPW",
      port: 6432,
      prepared_statements: "false",
      pool: "20",
      reconnect: "true"
    }

    test_replica_url = "#{test_config[:adapter]}://#{test_config[:username]}:#{test_config[:password]}@#{test_config[:host]}:#{test_config[:port]}/#{test_config[:database]}?prepared_statements=#{test_config[:prepared_statements]}&pool=#{test_config[:pool]}&reconnect=#{test_config[:reconnect]}"

    ENV.stub :[], test_replica_url, 'DATABASE_REPLICA_URL' do
      s = FreshConnection::ConnectionSpecification.new(:replica)
      s.stub(:base_config, {}) do
        config = s.spec.config

        assert_equal test_config[:host], config[:host]
        assert_equal test_config[:database], config[:database]
        assert_equal test_config[:username], config[:username]
        assert_equal test_config[:adapter], config[:adapter]
        assert_equal test_config[:password], config[:password]
        assert_equal test_config[:port], config[:port]
        assert_equal test_config[:prepared_statements], config[:prepared_statements]
        assert_equal test_config[:pool], config[:pool]
        assert_equal test_config[:reconnect], config[:reconnect]
      end
    end
  end
end
