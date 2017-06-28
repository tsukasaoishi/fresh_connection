require "test_helper"

class ReplicaConnectionSpecificationNameTest < Minitest::Test

  class Tel2 < Replica2
    self.table_name = :tel
  end

  test "equal replica_connection_specification_name of establish_fresh_connection" do
    assert_equal "replica1", User.replica_connection_specification_name
    assert_equal "replica2", Tel.replica_connection_specification_name
  end

  test "equal 'replica' when not specific replica_connection_specification_name" do
    Tel2.establish_fresh_connection
    assert_equal "replica", Tel2.replica_connection_specification_name
  end

  test "older 'slave' usage becomes 'replica' usage" do
    Tel2.establish_fresh_connection :slave
    assert_equal "replica", Tel2.replica_connection_specification_name
  end
end

