require "test_helper"

class ReplicaSpecNameTest < Minitest::Test
  class Tel2 < Replica2
    self.table_name = :tel
  end

  test "equal replica_spec_name of establish_fresh_connection" do
    assert_equal "replica1", User.replica_spec_name
    assert_equal "replica2", Tel.replica_spec_name
  end
end
