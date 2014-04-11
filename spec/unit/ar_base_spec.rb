require 'spec_helper'

describe ActiveRecord::Base do
  context ".slave_connection" do
    it "return Mysql2Adapter object" do
      expect(User.slave_connection).to be_a(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
    end
  end

  context ".slave_group" do
    class Tel2 < Slave2
      self.table_name = :tel
    end

    it "equal group_name of establish_fresh_connection" do
      expect(User.slave_group).to eq("slave1")
      expect(Tel.slave_group).to eq("slave2")
    end

    it "equal 'slave' when not specific group_name" do
      Tel2.establish_fresh_connection
      expect(Tel2.slave_group).to eq("slave")
    end
  end

  context ".master_db_only?" do
    class User2 < Parent
      self.table_name = :users
    end

    it "childrend of master_db_only class is master_db_only" do
      expect(User2.master_db_only?).to be_false
      Parent.master_db_only!
      expect(User2.master_db_only?).to be_true
    end

    it "not effect other class" do
      Parent.master_db_only!
      expect(Address.master_db_only?).to be_false
    end
  end
end
