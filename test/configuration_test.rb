require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    super
    @original_put_aside = FreshConnection.put_aside
    @original_recovery = FreshConnection.recovery
    @original_retry_limit = FreshConnection.retry_limit
  end

  def teardown
    FreshConnection.put_aside = @original_put_aside
    FreshConnection.recovery = @original_recovery
    FreshConnection.retry_limit = @original_retry_limit
    super
  end

  test "version is 3.1.4 and deprecation horizon is 3.2.0" do
    assert_equal "3.1.4", FreshConnection::VERSION
    assert_equal "3.2.0", FreshConnection.deprecator.deprecation_horizon
  end

  test "default configuration values maintain backward compatibility" do
    assert_equal true, FreshConnection.put_aside
    assert_equal true, FreshConnection.recovery
    assert_equal 3, FreshConnection.retry_limit
  end

  test "configure block updates settings" do
    FreshConnection.configure do |config|
      config.put_aside = false
      config.recovery = false
      config.retry_limit = 5
    end

    assert_equal false, FreshConnection.put_aside
    assert_equal false, FreshConnection.recovery
    assert_equal 5, FreshConnection.retry_limit
  end

  test "retry_limit clamps negative values to 0" do
    FreshConnection.retry_limit = -3
    assert_equal 0, FreshConnection.retry_limit

    FreshConnection.retry_limit = nil
    assert_equal 0, FreshConnection.retry_limit
  end

  test "retry_limit = 0 disables retries" do
    FreshConnection.retry_limit = 0
    attempts = 0
    raise_error = lambda { |*args, &block|
      attempts += 1
      raise ActiveRecord::StatementInvalid, "error"
    }

    FreshConnection::AccessControl.stub(:access, raise_error) do
      FreshConnection::AccessControl.stub(:recovery?, true) do
        assert_raises(ActiveRecord::StatementInvalid) do
          User.take
        end
      end
    end

    assert_equal 1, attempts
  end

  test "establish_fresh_connection emits deprecation warning for 3.2.0" do
    warnings = []
    original_behavior = FreshConnection.deprecator.behavior
    FreshConnection.deprecator.behavior = ->(message, *_args) { warnings << message }

    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
    klass.establish_fresh_connection :replica1

    assert warnings.any? { |w| w.include?("establish_fresh_connection is deprecated") && w.include?("3.2.0") }
  ensure
    FreshConnection.deprecator.behavior = original_behavior
  end

  test "connection_manager= emits deprecation warning for 3.2.0 and clears old connections" do
    warnings = []
    original_behavior = FreshConnection.deprecator.behavior
    FreshConnection.deprecator.behavior = ->(message, *_args) { warnings << message }

    old_conn = User.replica_connection
    old_conn.verify!
    assert old_conn.active?
    custom_mgr = Class.new(FreshConnection::AbstractConnectionManager)
    FreshConnection.connection_manager = custom_mgr

    assert warnings.any? { |w| w.include?("FreshConnection.connection_manager= is deprecated") && w.include?("3.2.0") }
    assert FreshConnection.custom_connection_manager?
    refute old_conn.active?
  ensure
    FreshConnection.connection_manager = nil
    FreshConnection.deprecator.behavior = original_behavior
  end

  test "DATABASE_*_URL emits deprecation warning for 3.2.0" do
    warnings = []
    original_behavior = FreshConnection.deprecator.behavior
    previous_url = ENV["DATABASE_DEPRECATION_TEST_URL"]
    FreshConnection.deprecator.behavior = ->(message, *_args) { warnings << message }
    ENV["DATABASE_DEPRECATION_TEST_URL"] = "mysql2://localhost/test_replica"

    spec = FreshConnection::ConnectionSpecification.new(:deprecation_test)
    spec.stub(:base_config, {}) do
      spec.spec
    end

    assert warnings.any? { |w| w.include?("DATABASE_DEPRECATION_TEST_URL") && w.include?("3.2.0") }
  ensure
    ENV["DATABASE_DEPRECATION_TEST_URL"] = previous_url
    FreshConnection.deprecator.behavior = original_behavior
  end

  test "nested database.yml replica stanza emits deprecation warning for 3.2.0" do
    warnings = []
    original_behavior = FreshConnection.deprecator.behavior
    previous_url = ENV["DATABASE_NESTED_TEST_URL"]
    FreshConnection.deprecator.behavior = ->(message, *_args) { warnings << message }
    ENV["DATABASE_NESTED_TEST_URL"] = nil

    spec = FreshConnection::ConnectionSpecification.new(:nested_test)
    spec.stub(:base_config, { adapter: "mysql2", nested_test: { host: "replica_host", database: "test_db" } }) do
      spec.spec
    end

    assert warnings.any? { |w| w.include?("nested 'nested_test' stanza") && w.include?("3.2.0") }
  ensure
    ENV["DATABASE_NESTED_TEST_URL"] = previous_url
    FreshConnection.deprecator.behavior = original_behavior
  end
end
