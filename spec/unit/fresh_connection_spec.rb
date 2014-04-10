require 'spec_helper'

describe FreshConnection do
  context "selct is to slave" do
    before(:each) do
      @user = User.find(1)
      @user_included = User.includes(:address, :tels).find(1)
    end

    it "select from User is to access to slave1" do
      @user.name.should be_include("slave1")
    end

    it "select from Address is to access to slave1" do
      Address.first.prefecture.should be_include("slave1")
      @user.address.prefecture.should be_include("slave1")
      @user_included.address.prefecture.should be_include("slave1")
    end

    it "select from Address is to access to slave2" do
      Tel.first.number.should be_include("slave2")
      @user.tels.first.number.should be_include("slave2")
      @user_included.tels.first.number.should be_include("slave2")
    end
  end
end
