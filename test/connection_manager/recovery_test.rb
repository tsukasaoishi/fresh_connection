require "test_helper"
require "fresh_connection/connection_manager"

# The top-level RecoveryTest stubs AccessControl.recovery?, so it only exercises
# the retry loop, not the real detection logic. This covers the actual
# ConnectionManager#recovery? behaviour: a dead replica connection is detected
# and put aside, and a healthy one is left alone.
class ConnectionManagerRecoveryTest < Minitest::Test
  def setup
    super
    @cm = FreshConnection::ConnectionManager.new
  end

  def teardown
    @cm.clear_all_connections!
  end

  test "recovery? detects a dead connection, puts it aside, and recovers" do
    conn = @cm.replica_connection
    conn.disconnect!
    refute conn.active?

    assert @cm.recovery?, "an inactive connection should trigger recovery"

    # After recovery a fresh, working connection is obtainable.
    assert @cm.replica_connection.select_value("SELECT 1")
  end

  test "recovery? returns false when the connection is healthy" do
    @cm.replica_connection.select_value("SELECT 1") # ensure it is connected/active

    refute @cm.recovery?, "a healthy connection must not be torn down"
  end
end
