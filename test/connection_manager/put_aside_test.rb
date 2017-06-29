require "test_helper"

class PutAsideTest < Minitest::Test
  def setup
    super
    @cm = FreshConnection::ConnectionManager.new
  end

  def teardown
    @cm.clear_all_connections!
  end

  test "current thread connection disconnect" do
    current_connection = @cm.replica_connection
    assert current_connection.in_use?
    @cm.put_aside!
    refute current_connection.in_use?
    refute current_connection.active?

    connections = @cm.instance_variable_get("@pool").connections
    refute connections.include?(current_connection)
  end
end
