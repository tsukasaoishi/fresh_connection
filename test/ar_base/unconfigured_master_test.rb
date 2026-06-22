require "test_helper"

# Regression guard for the adapter raw-connection / type-map / statement-cache
# swap. On AR 7.2+ the @verified pin in BaseAdapter skips the master adapter's
# configure_connection, so when the very first query after a (re)connect is a
# replica-bound read, the master adapter has nil @type_map / @type_map_for_results.
# Previously this was only hit non-deterministically (depending on test order);
# here we force the condition so any missing ivar in the swap fails every time.
class UnconfiguredMasterTest < Minitest::Test
  def teardown
    # Re-establish a clean master connection for subsequent tests.
    ActiveRecord::Base.connection_pool.disconnect!
  end

  test "replica read works when master adapter is freshly (re)connected" do
    # Drop the master connection so the master adapter is unconfigured on next use.
    ActiveRecord::Base.connection_pool.disconnect!

    # This read is routed to replica1 through the master adapter; it must succeed
    # and decode results even though the master adapter never ran configure_connection.
    assert_includes User.where(id: 1).first.name, "replica1"
  end

  test "replica read of every column type works on a fresh master adapter" do
    ActiveRecord::Base.connection_pool.disconnect!

    # Exercise the result-casting path (integers, strings, timestamps) which on
    # PostgreSQL relies on the adapter's @type_map.
    user = User.where(id: 1).first
    assert_kind_of Integer, user.id
    assert_includes user.name, "replica1"
    assert user.created_at
  end
end
