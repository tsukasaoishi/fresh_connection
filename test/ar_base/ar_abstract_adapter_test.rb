require "test_helper"

class AbstractAdapterTest < Minitest::Test
  class FakeAddress < ActiveRecord::Base
    self.table_name = :addresses
    establish_fresh_connection :fake_replica
  end

  def setup
    ActiveRecord::Base.connection.clear_query_cache
  end

  test "cache_query is correct after select once" do
    filename = File.join(__dir__, "../../log/sql.log")

    Address.cache do
      Address.find(1)
      Address.find(1)
      last_line = `tail -1 #{filename}`
      assert_match /CACHE/, last_line
    end
  end

  test "cache_query is correct after master update" do
    old_pref = SecureRandom.hex(3)
    a = FakeAddress.create(prefecture: old_pref)

    Address.cache do
      new_pref = old_pref + "1"
      b = FakeAddress.find(a.id)
      b.prefecture = new_pref
      b.save!

      address = FakeAddress.find(a.id)
      assert_equal new_pref, address.prefecture
    end
  end
end
