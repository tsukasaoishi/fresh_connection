require 'spec_helper'

describe FreshConnection do
  before(:each) do
    @user = User.first
  end

  context "access to slave" do
    it "select from User is to access to slave1" do
      [
        @user.name,
        Address.first.user.name,
        Tel.first.user.name,
      ].should be_all {|n| n.include?("slave1")}
    end

    it "select from Address is to access to slave1" do
      [
        Address.first.prefecture,
        @user.address.prefecture
      ].should be_all {|n| n.include?("slave1")}
    end

    it "select from Address is to access to slave2" do
      [
        Tel.first.number,
        @user.tels.first.number
      ].should be_all {|n| n.include?("slave2")}
    end

    it "select with join is to access to slave1" do
      User.joins(:address).where("addresses.user_id = 1").first.\
        name.should be_include("slave1")
    end
  end

  context "access to master" do
    it "in transaction" do
      User.transaction do
        @user.name.should be_include("slave1")
        [
          Address.first.user.name,
          Address.first.prefecture,
          Tel.first.number,
          Tel.first.user.name,
          @user.address.prefecture,
          @user.tels.first.number,
          User.joins(:address).where("addresses.user_id = 1").first.name
        ].should be_all {|n| n.include?("master")}

      end
    end

    it "specify readonly(false)" do
      [
        Address.readonly(false).first.prefecture,
        Address.includes(:user).readonly(false).first.user.name,
        Tel.readonly(false).first.number,
        Tel.includes(:user).readonly(false).first.user.name,
        @user.tels.readonly(false).first.number,
        User.includes(:tels).readonly(false).first.tels.first.number,
        User.includes(:address).readonly(false).first.address.prefecture,
        User.joins(:address).where("addresses.user_id = 1").readonly(false).first.name
      ].should be_all {|n| n.include?("master")}
    end
  end
end
