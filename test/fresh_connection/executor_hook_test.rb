require "test_helper"
require "fresh_connection/executor_hook"

# The replica connection lifecycle hooks were untested:
# - ExecutorHook#complete is what Rails calls at the end of each request to put
#   replica connections aside.
# - ArBase#clear_all_replica_connections! disconnects all replica connections.
class ExecutorHookTest < Minitest::Test
  test "executor hook completion puts the replica connection aside" do
    User.where(id: 1).first # establish/activate the replica1 connection
    conn = User.replica_connection
    assert conn.active?

    FreshConnection::ExecutorHook.complete

    refute conn.active?, "replica connection should be disconnected on request completion"
  end

  test "clear_all_replica_connections! disconnects the replica connection" do
    User.where(id: 1).first
    conn = User.replica_connection
    assert conn.active?

    User.clear_all_replica_connections!

    refute conn.active?
  end
end
