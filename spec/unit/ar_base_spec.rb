require 'spec_helper'

describe ActiveRecord::Base do
  class Parent < ActiveRecord::Base
    self.abstract_class = true
  end

  Object.class_eval do remove_const :User end

  class User < Parent
  end

  context ".master_db_only?" do
    it "childrend of master_db_only class is master_db_only" do
      User.master_db_only?.should be_false
      Parent.master_db_only!
      User.master_db_only?.should be_true
    end

    it "not effect other class" do
      Parent.master_db_only!
      Address.master_db_only?.should be_false
    end
  end
end
