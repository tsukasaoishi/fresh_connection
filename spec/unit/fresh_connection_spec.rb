require 'spec_helper'

describe FreshConnection do
  before(:each) do
    @user = User.where(id: 1).first
  end

  context "access to slave" do
    it "select from User is to access to slave1" do
      data = [
        @user.name,
        Address.first.user.name,
        Tel.first.user.name,
      ]

      expect(data).to be_all{|n| n.include?("slave1")}
    end

    it "select from Address is to access to slave1" do
      data = [
        Address.first.prefecture,
        @user.address.prefecture
      ]

      expect(data).to be_all{|n| n.include?("slave1")}
    end

    it "select from Address is to access to slave2" do
      data = [
        Tel.first.number,
        @user.tels.first.number
      ]

      expect(data).to be_all{|n| n.include?("slave2")}
    end

    it "select with join is to access to slave1" do
      name = User.joins(:address).where("addresses.user_id = 1").where(id: 1).first.name
      expect(name).to be_include("slave1")
    end

    it "pluck is access to slave1" do
      expect(User.where(id: 1).pluck(:name).first).to be_include("slave")
    end

    it "pluck returns empty array when result of condition is empty" do
      expect(User.limit(0).pluck(:name)).to be_empty
    end

    it "count is access to slave" do
      expect(User.where(name: "Other").count).to eq(2)
    end

    it "reload is to access to slave1" do
      expect(@user.reload.name).to be_include("slave1")
    end
  end

  context "access to master" do
    it "in transaction" do
      User.transaction do
        expect(@user.name).to be_include("slave1")
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
        expect(data).to be_all{|n| n.include?("master")}

        expect(User.where(name: "Other").count).to eq(1)
      end
    end

    it "in with_master" do
      User.with_master do
        expect(@user.name).to be_include("slave1")
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
        expect(data).to be_all{|n| n.include?("master")}

        expect(User.where(name: "Other").count).to eq(1)
      end
    end

    it "specify read_master" do
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

      expect(data).to be_all{|n| n.include?("master")}
      expect(User.where(name: "Other").read_master.count).to eq(1)
    end

    it "specify readonly(false)" do
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

        expect(data).to be_all{|n| n.include?("master")}
        expect(User.where(name: "Other").readonly(false).count).to eq(1)
        expect(User.where(name: "Other").count(:readonly => false)).to eq(1)
      end
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
      expect(Address3.first.prefecture).to be_include("master")
    end

    it "parent is master_db_only model" do
      expect(Tel3.first.number).to be_include("master")
    end

    it "not effect other models" do
      expect(Address.first.prefecture).to be_include("slave1")
      expect(Tel.first.number).to be_include("slave2")
    end
  end
end
