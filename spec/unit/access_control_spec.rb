require 'spec_helper'

describe FreshConnection::AccessControl do
  before(:each) do
    @ac = FreshConnection::AccessControl
  end

  context ".access" do
    it "persisted first state(slave)" do
      ret = []
      @ac.access(true) do
        @ac.access(true) do
          ret << @ac.slave_access?
          @ac.access(false) do
            ret << @ac.slave_access?
          end
        end
      end
      ret.should be_all{|item| item}
    end

    it "persisted first state(master)" do
      ret = []
      @ac.access(false) do
        @ac.access(true) do
          ret << @ac.slave_access?
          @ac.access(false) do
            ret << @ac.slave_access?
          end
        end
      end
      ret.should_not be_all{|item| item}
    end

    it "outside is always master" do
      ret = []
      ret << @ac.slave_access?
      @ac.access(true){}
      ret << @ac.slave_access?
      ret.should_not be_all{|item| item}
    end
  end

  context ".force_master_access" do
    it "forced master state" do
      @ac.access(true) do
        @ac.force_master_access do
          @ac.slave_access?.should be_false
        end
      end
    end

    it "not effect outside" do
      @ac.access(true) do
        @ac.force_master_access {}
        @ac.slave_access?.should be_true
      end
    end
  end
end
