require "test_helper"

class ReadMasterTest < Minitest::Test
  test "read_master applies only to its own relation" do
    # read_master spawns a relation that reads from master ...
    assert_includes Address.read_master.first.prefecture, "master"
    # ... and must not leak into a separate relation, which still hits the replica.
    assert_includes Address.first.prefecture, "replica1"
  end

  test "read_master! mutates the receiver relation" do
    relation = Address.all
    assert_same relation, relation.read_master!
    assert_includes relation.first.prefecture, "master"
  end
end
