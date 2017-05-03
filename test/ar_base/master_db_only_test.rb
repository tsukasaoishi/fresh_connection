require "test_helper"

class MasterDbOnlyTest < Minitest::Test

  class User2 < Parent
    self.table_name = :users
  end

  test "childrend of master_db_only class is master_db_only" do
    begin
      assert !(User2.master_db_only?)
      Parent.master_db_only!
      assert User2.master_db_only?
    ensure
      Parent.instance_variable_set(:@_fresh_connection_master_only, nil)
    end
  end

  test "not effect other class" do
    begin
      Parent.master_db_only!
      refute Address.master_db_only?
    ensure
      Parent.instance_variable_set(:@_fresh_connection_master_only, nil)
    end
  end
end
