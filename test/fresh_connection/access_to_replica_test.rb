require "test_helper"

class AccessToReplicaTest < Minitest::Test
  def setup
    super
    @user = User.where(id: 1).first
  end

  test "select from User is to access to replica1" do
    data = [
      @user.name,
      Address.first.user.name,
      Tel.first.user.name,
    ]

    assert data.all?{|n| n.include?("replica1")}
  end

  test "select from Address is to access to replica1" do
    data = [
      Address.first.prefecture,
      @user.address.prefecture
    ]

    assert data.all?{|n| n.include?("replica1")}
  end

  test "select from Address is to access to replica2" do
    data = [
      Tel.first.number,
      @user.tels.first.number
    ]

    assert data.all?{|n| n.include?("replica2")}
  end

  test "select with join is to access to replica1" do
    name = User.joins(:address).where("addresses.user_id = 1").where(id: 1).first.name
    assert_includes name, "replica1"
  end

  test "pluck is access to replica1" do
    assert_includes User.where(id: 1).pluck(:name).first, "replica"
  end

  test "pluck returns empty array when result of condition is empty" do
    assert_empty User.limit(0).pluck(:name)
  end

  test "count is access to replica" do
    assert_equal 2, User.where(name: "Other").count
  end

  test "reload is to access to replica1" do
    assert_includes @user.reload.name, "replica1"
  end

  test "exists? is to access to replica" do
    assert User.where(id: 3).exists?
  end
end
