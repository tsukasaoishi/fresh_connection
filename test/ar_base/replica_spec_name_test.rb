require "test_helper"

class ReplicaSpecNameTest < Minitest::Test
  class Tel2 < Replica2
    self.table_name = :tel
  end

  test "equal replica_spec_name of establish_fresh_connection" do
    assert_equal "replica1", User.replica_spec_name
    assert_equal "replica2", Tel.replica_spec_name
  end

  test "equal 'replica' when not specific replica_spec_name" do
    Tel2.establish_fresh_connection
    assert_equal "replica", Tel2.replica_spec_name
  end
end
