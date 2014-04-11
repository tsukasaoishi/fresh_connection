require 'spec_helper'

describe "recovery when Mysql down" do
  class User3 < ActiveRecord::Base
    self.table_name = "users"

    class << self
      attr_writer :limit_time

      def slave_connection
        @access_time ||= 0
        @access_time += 1
        if @access_time > limit_time
          super
        else
          raise ActiveRecord::StatementInvalid, "MySQL server has gone away"
        end
      end

      def limit_time
        @limit_time || 1
      end
    end
  end

  it "enable recovery" do
    User3.limit_time = 1
    expect {
      User3.first
    }.not_to raise_error
  end

  it "raise exception when retry over" do
    User3.limit_time = 100
    expect {
      User3.first
    }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
