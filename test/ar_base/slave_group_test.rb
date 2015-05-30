require "test_helper"

class SlaveGroupTest < Minitest::Test
  class Tel2 < Slave2
    self.table_name = :tel
  end

  test "equal group_name of establish_fresh_connection" do
    assert_equal "slave1", User.slave_group
    assert_equal "slave2", Tel.slave_group
  end

  test "equal 'slave' when not specific group_name" do
    Tel2.establish_fresh_connection
    assert_equal "slave", Tel2.slave_group
  end
end

