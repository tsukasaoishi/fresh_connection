require "test_helper"

class ClearAllConnectionTest < Minitest::Test
  def setup
    @cm = FreshConnection::ConnectionManager.new
  end

  def teardown
    @cm.clear_all_connections!
  end

  test "all connections disconnect" do
    threads_num = 5
    threads = []
    threads_num.times do |i|
      threads << Thread.new do
        @cm.slave_connection
      end
    end
    threads.each(&:join)

    connections = @cm.instance_variable_get("@connections")

    @cm.clear_all_connections!
    assert_empty @cm.instance_variable_get("@connections")
    connections.each_value do |c|
      refute c.active?
    end
  end
end
