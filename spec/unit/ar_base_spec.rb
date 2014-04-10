require 'spec_helper'

describe ActiveRecord::Base do
  context ".slave_connection" do
    it "return Mysql2Adapter object" do
      User.slave_connection.should be_a(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
    end
  end

  context ".slave_group" do
    class Tel2 < Slave2
      self.table_name = :tel
    end

    it "equal group_name of establish_fresh_connection" do
      User.slave_group.should eq("slave1")
      Tel.slave_group.should eq("slave2")
    end

    it "equal 'slave' when not specific group_name" do
      Tel2.establish_fresh_connection
      Tel2.slave_group.should eq("slave")
    end
  end

  context ".master_db_only?" do
    class User2 < Parent
      self.table_name = :users
    end

    it "childrend of master_db_only class is master_db_only" do
      User2.master_db_only?.should be_false
      Parent.master_db_only!
      User2.master_db_only?.should be_true
    end

    it "not effect other class" do
      Parent.master_db_only!
      Address.master_db_only?.should be_false
    end
  end
end
