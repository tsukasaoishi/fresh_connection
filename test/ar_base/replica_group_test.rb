require "test_helper"

class ReplicaGroupTest < Minitest::Test
  class Tel2 < Replica2
    self.table_name = :tel
  end

  test "equal group_name of establish_fresh_connection" do
    assert_equal "replica1", User.replica_group
    assert_equal "replica2", Tel.replica_group
  end

  test "equal 'replica' when not specific group_name" do
    Tel2.establish_fresh_connection
    assert_equal "replica", Tel2.replica_group
  end

  test "older 'slave' usage becomes 'replica' usage" do
    Tel2.establish_fresh_connection :slave
    assert_equal "replica", Tel2.replica_group
  end
end

