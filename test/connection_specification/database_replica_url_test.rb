require "test_helper"

class DatabaseReplicaUrlTest < Minitest::Test
  def setup
    @previous_replica_url = ENV["DATABASE_REPLICA_URL"]
  end

  def teardown
    ENV["DATABASE_REPLICA_URL"] = @previous_replica_url
    ENV["DATABASE_REPLICA_MYSQL2_URL"] = nil
    ENV["DATABASE_REPLICA_POSTGRESQL_URL"] = nil
  end

  test "use standard config/database.yml spec when DATABASE_REPLICA_URL is not defined" do
    test_config = { host: 'test_host', database: 'test_db', adapter: "mysql2" }
    ENV["DATABASE_REPLICA_URL"] = nil

    s = FreshConnection::ConnectionSpecification.new(:replica)
    s.stub(:base_config, { replica: test_config }) do
      config = s.spec.respond_to?(:config) ? s.spec.config : s.spec.db_config.configuration_hash

      assert_equal test_config[:host], config[:host]
      assert_equal test_config[:database], config[:database]
      assert_equal test_config[:adapter], config[:adapter]
      assert_nil config[:username]
      assert_nil config[:password]
    end
  end

  test "use url components when DATABASE_REPLICA_URL is defined" do
    test_config = {
      adapter: "postgresql",
      host: SecureRandom.hex(6),
      database: SecureRandom.hex(5),
      username: SecureRandom.hex(4),
      password: SecureRandom.hex(3),
      port: rand(10000) + 1,
      prepared_statements: %w(true false).sample,
      pool: (rand(100) + 1).to_s,
      reconnect: %w(true false).sample
    }

    test_replica_url = "#{test_config[:adapter]}://#{test_config[:username]}:#{test_config[:password]}@#{test_config[:host]}:#{test_config[:port]}/#{test_config[:database]}?prepared_statements=#{test_config[:prepared_statements]}&pool=#{test_config[:pool]}&reconnect=#{test_config[:reconnect]}"
    ENV["DATABASE_REPLICA_URL"] = test_replica_url

    s = FreshConnection::ConnectionSpecification.new(:replica)
    s.stub(:base_config, {}) do
      config = s.spec.respond_to?(:config) ? s.spec.config : s.spec.db_config.configuration_hash

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

  test "use url components when some DATABASE_REPLICA_URL is defined" do
    test_config = {
      mysql2: {
        host: SecureRandom.hex(3),
        database: SecureRandom.hex(4),
        username: SecureRandom.hex(5),
        password: SecureRandom.hex(6),
        port: rand(10000) + 1,
        pool: (rand(100) + 1).to_s
      },
      postgresql: {
        host: SecureRandom.hex(7),
        database: SecureRandom.hex(8),
        username: SecureRandom.hex(9),
        password: SecureRandom.hex(10),
        port: rand(10000) + 1,
        pool: (rand(100) + 1).to_s
      }
    }

    c = test_config[:mysql2]
    test_replica_mysql_url = "mysql2://#{c[:username]}:#{c[:password]}@#{c[:host]}:#{c[:port]}/#{c[:database]}?pool=#{c[:pool]}"
    ENV["DATABASE_REPLICA_MYSQL2_URL"] = test_replica_mysql_url

    c = test_config[:postgresql]
    test_replica_postgresql_url = "postgresql://#{c[:username]}:#{c[:password]}@#{c[:host]}:#{c[:port]}/#{c[:database]}?pool=#{c[:pool]}"
    ENV["DATABASE_REPLICA_POSTGRESQL_URL"] = test_replica_postgresql_url

    %i(mysql2 postgresql).each do |spec_name|
      s = FreshConnection::ConnectionSpecification.new("replica_#{spec_name}")
      s.stub(:base_config, {}) do
        config = s.spec.respond_to?(:config) ? s.spec.config : s.spec.db_config.configuration_hash
        tc = test_config[spec_name]

        assert_equal spec_name.to_s, config[:adapter]
        assert_equal tc[:host], config[:host]
        assert_equal tc[:database], config[:database]
        assert_equal tc[:username], config[:username]
        assert_equal tc[:password], config[:password]
        assert_equal tc[:port], config[:port]
        assert_equal tc[:pool], config[:pool]
      end
    end
  end

  test "use merge url components and database.yml configuration" do
    test_config = {
      adapter: "mysql2",
      host: SecureRandom.hex(6),
      database: SecureRandom.hex(5),
      username: SecureRandom.hex(4),
      password: SecureRandom.hex(3),
      port: rand(10000) + 1,
      reconnect: %w(true false).sample
    }
    base_config = {
      host: "bad host",
      database: "bad database",
      username: "bad username",
      pool: (rand(100) + 1).to_s,
    }

    test_replica_url = "#{test_config[:adapter]}://#{test_config[:username]}:#{test_config[:password]}@#{test_config[:host]}:#{test_config[:port]}/#{test_config[:database]}?reconnect=#{test_config[:reconnect]}"
    ENV["DATABASE_REPLICA_URL"] = test_replica_url

    s = FreshConnection::ConnectionSpecification.new(:replica)
    s.stub(:base_config, base_config) do
      config = s.spec.respond_to?(:config) ? s.spec.config : s.spec.db_config.configuration_hash

      tc = base_config.merge!(test_config)
      assert_equal tc[:host], config[:host]
      assert_equal tc[:database], config[:database]
      assert_equal tc[:username], config[:username]
      assert_equal tc[:adapter], config[:adapter]
      assert_equal tc[:password], config[:password]
      assert_equal tc[:port], config[:port]
      assert_equal tc[:pool], config[:pool]
      assert_equal tc[:reconnect], config[:reconnect]
    end
  end
end
