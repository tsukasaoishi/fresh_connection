require "test_helper"

class MergeTest < Minitest::Test
  test "enable merge of read_master" do
    name = Address.all.merge(Address.read_master).first.prefecture
    assert name.include?("master")
  end
end
