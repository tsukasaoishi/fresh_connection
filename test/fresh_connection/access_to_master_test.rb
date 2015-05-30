require "test_helper"

class AccessToSlaveTest < Minitest::Test
  def setup
    @user = User.where(id: 1).first
  end

  test "in transaction" do
    User.transaction do
      assert_includes @user.name, "slave1"
      data = [
        Address.first.user.name,
        Address.first.prefecture,
        Tel.first.number,
        Tel.first.user.name,
        @user.address.prefecture,
        @user.tels.first.number,
        User.joins(:address).where(id: 1).where("addresses.user_id = 1").first.name,
        User.where(id: 1).pluck(:name).first,
        @user.reload.name
      ]
      assert data.all?{|n| n.include?("master")}
      assert_equal 1, User.where(name: "Other").count
    end
  end

  test "in with_master" do
    User.with_master do
      assert_includes @user.name, "slave1"
      data = [
        Address.first.user.name,
        Address.first.prefecture,
        Tel.first.number,
        Tel.first.user.name,
        @user.address.prefecture,
        @user.tels.first.number,
        User.joins(:address).where(id: 1).where("addresses.user_id = 1").first.name,
        User.where(id: 1).pluck(:name).first,
        @user.reload.name
      ]
      assert data.all?{|n| n.include?("master")}
      assert_equal 1, User.where(name: "Other").count
    end
  end

  test "specify read_master" do
    data = [
      Address.read_master.first.prefecture,
      Address.includes(:user).read_master.first.user.name,
      Tel.read_master.first.number,
      Tel.includes(:user).read_master.first.user.name,
      @user.tels.read_master.first.number,
      User.where(id: 1).includes(:tels).read_master.first.tels.first.number,
      User.where(id: 1).includes(:address).read_master.first.address.prefecture,
      User.where(id: 1).joins(:address).where("addresses.user_id = 1").read_master.first.name,
      User.where(id: 1).read_master.pluck(:name).first
    ]
    assert data.all?{|n| n.include?("master")}
    assert_equal 1, User.where(name: "Other").read_master.count
  end

  test "specify readonly(false)" do
    ActiveSupport::Deprecation.silence do
      data = [
        Address.readonly(false).first.prefecture,
        Address.includes(:user).readonly(false).first.user.name,
        Tel.readonly(false).first.number,
        Tel.includes(:user).readonly(false).first.user.name,
        @user.tels.readonly(false).first.number,
        User.where(id: 1).includes(:tels).readonly(false).first.tels.first.number,
        User.where(id: 1).includes(:address).readonly(false).first.address.prefecture,
        User.where(id: 1).joins(:address).where("addresses.user_id = 1").readonly(false).first.name,
        User.where(id: 1).readonly(false).pluck(:name).first
      ]
      assert data.all?{|n| n.include?("master")}
      assert_equal 1, User.where(name: "Other").readonly(false).count
      assert_equal 1, User.where(name: "Other").count(:readonly => false)
    end
  end
end
