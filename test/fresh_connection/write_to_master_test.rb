require "test_helper"

# The suite verifies read routing thoroughly but never asserts that writes are
# sent to the master. The test DBs are independent (not real replication), so a
# row written to master is invisible to the replica DBs - we use that to prove
# the INSERT/UPDATE/DELETE landed on master while plain reads hit the replica.
#
# `read_master` reads from master; a plain query reads from the replica.
class WriteToMasterTest < Minitest::Test
  def teardown
    User.with_master { User.where("name LIKE ?", "wtest-%").delete_all }
    super
  end

  test "create writes to master and is invisible to the replica" do
    name = "wtest-#{SecureRandom.hex(4)}"

    user = User.create!(name: name)

    assert user.persisted?
    assert User.read_master.where(name: name).exists?, "INSERT should hit master"
    refute User.where(name: name).exists?, "replica DB must not see a master-only INSERT"
  end

  test "update writes to master" do
    name = "wtest-#{SecureRandom.hex(4)}"
    user = User.create!(name: name)

    user.update!(name: "#{name}-upd")

    assert User.read_master.where(name: "#{name}-upd").exists?, "UPDATE should hit master"
    refute User.read_master.where(name: name).exists?
  end

  test "destroy writes to master" do
    name = "wtest-#{SecureRandom.hex(4)}"
    user = User.create!(name: name)

    user.destroy!

    refute User.read_master.where(name: name).exists?, "DELETE should hit master"
  end
end
