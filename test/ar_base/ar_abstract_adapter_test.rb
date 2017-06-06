require "test_helper"
#require 'pry-byebug'

class AbstractAdapterTest < Minitest::Test

  class Tel < ActiveRecord::Base
    establish_fresh_connection :fake_replica
    enable_replica_query_cache_sync!

    belongs_to :user
  end

  def setup
    ActiveRecord::Base.connection.clear_query_cache
  end

  test "cache_query is incorrect after master update with replica cache syncing disabled" do

    Tel.cache do

      Tel.replica_connection.enable_query_cache!
      Tel.disable_replica_query_cache_sync!

      tel = Tel.find(1)
      assert_match(/master/ , tel.number)
      rconn = Tel.replica_connection
      mconn = Tel.master_connection

      refute rconn.query_cache.empty?
      assert mconn.query_cache.empty?

      orig_number = tel.number
      tel.number = tel.number.sub(/master/,'fake_replica')
      tel.save!
      assert mconn.query_cache.empty?
      refute rconn.query_cache.empty?       # the replica cache should still have some contents after an update

      tel2 = Tel.find(1)
      refute_equal tel2.number, tel.number  # the replica cache contents should be stale

      tel.number = orig_number
      tel.save!
    end

  end

  test "cache_query is correct after master update with replica cache syncing enabled" do

    Tel.cache do

      Tel.replica_connection.enable_query_cache!
      Tel.enable_replica_query_cache_sync!

      tel = Tel.find(1)
      assert_match(/master/ , tel.number)
      rconn = Tel.replica_connection
      mconn = Tel.master_connection

      refute rconn.query_cache.empty?     # the replica cache should have some contents
      assert mconn.query_cache.empty?     # the master connection cache is always empty

      orig_number = tel.number
      tel.number = tel.number.sub(/master/,'fake_replica')
      tel.save!

      tel2 = Tel.find(1)
      assert_equal tel2.number, tel.number  # the replica should have pulled fresh, correct data

      tel.number = orig_number
      tel.save!
    end

  end

end

