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

  context "master_db_only model always access to master" do
    class Address3 < ActiveRecord::Base
      self.table_name = "addresses"
      master_db_only!
    end

    class Master < ActiveRecord::Base
      self.abstract_class = true
      master_db_only!
    end

    class Tel3 < Master
      self.table_name = "tels"
    end

    it "self is master_db_only model" do
      Address3.first.prefecture.should be_include("master")
    end

    it "parent is master_db_only model" do
      Tel3.first.number.should be_include("master")
    end

    it "not effect other models" do
      Address.first.prefecture.should be_include("slave1")
      Tel.first.number.should be_include("slave2")
    end
  end
end
