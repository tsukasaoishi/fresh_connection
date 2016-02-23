require "test_helper"

class PutAsideTest < Minitest::Test
  def setup
    @cm = FreshConnection::ConnectionManager.new
  end

  def teardown
    @cm.clear_all_connections!
  end

  test "current thread connection disconnect" do
    threads_num = 5
    threads = []
    threads_num.times do |i|
      threads << Thread.new do
        @cm.slave_connection
      end
    end
    threads.each(&:join)

    current_connection = @cm.slave_connection
    @cm.put_aside!
    refute current_connection.active?

    connections = @cm.instance_variable_get("@connections").all
    assert_equal threads_num, connections.size
    connections.each do |c|
      assert c.active?
      refute_equal current_connection, c
    end
  end
end
