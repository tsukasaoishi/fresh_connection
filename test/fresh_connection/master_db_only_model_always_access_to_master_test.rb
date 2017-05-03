require "test_helper"

class MasterDbOnlyModelAlwaysAccessToMasterTest < Minitest::Test
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

  def setup
    super
    @user = User.where(id: 1).first
  end

  test "self is master_db_only model" do
    assert_includes Address3.first.prefecture, "master"
  end

  test "parent is master_db_only model" do
    assert_includes Tel3.first.number, "master"
  end

  test "not effect other models" do
    assert_includes Address.first.prefecture, "replica1"
    assert_includes Tel.first.number, "replica2"
  end
end
