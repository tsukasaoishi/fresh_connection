require "test_helper"

class DatabaseReplicaUrlTest < Minitest::Test

  test_config = { replica: { host: 'test_host', database: 'test_db' } }

  test "use standard config/database.yml spec when DATABASE_REPLICA_URL is not defined" do

    ENV.stub :[], nil, 'DATABASE_REPLICA_URL'  do
      ActiveRecord::Base.connection_pool.stub :spec, test_config do
        factory = FreshConnection::ConnectionFactory.new(:replica)
        factory.define_singleton_method(:ar_spec) do
          Struct.new(:config).new(test_config)
        end
        spec = factory.__send__(:spec)
        assert_equal 'test_host',  spec[:host]
        assert_equal 'test_db',    spec[:database]
        assert_equal 'test_host',  spec["host"]
        assert_equal 'test_db',    spec["database"]
        assert_nil                 spec["username"]
        assert_nil                 spec["password"]
      end
    end

  end

  test "use url components when DATABASE_REPLICA_URL is defined" do

    test_replica_url = 'postgresql://procore_db:SECRETPW@localhost:6432/procore_test_db?prepared_statements=false&pool=20&reconnect=true'

    ENV.stub :[], test_replica_url, 'DATABASE_REPLICA_URL' do
      factory = FreshConnection::ConnectionFactory.new(:replica)
      factory.define_singleton_method(:ar_spec) do
        Struct.new(:config).new(test_config)
      end
      spec = factory.__send__(:spec)
      assert_equal 'procore_test_db',  spec["database"]
      assert_equal 'procore_db',       spec["username"]
      assert_equal 'procore_test_db',  spec[:database]
      assert_equal 'procore_db',       spec[:username]
      assert_equal 'postgresql',       spec[:adapter]
      assert_equal 'SECRETPW',         spec[:password]
      assert_equal 'localhost',        spec[:host]
      assert_equal 6432,               spec[:port]
      assert_equal 'procore_test_db',  spec[:database]
      assert_match(/\bfalse\b/ ,       spec[:prepared_statements])
      assert_match(/\b20\b/ ,          spec[:pool])
      assert_match(/\btrue\b/ ,        spec[:reconnect])
    end
  end

end
