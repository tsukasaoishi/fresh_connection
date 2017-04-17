require "test_helper"

class ForceMasterAccessTest < Minitest::Test
  def setup
    @ac = FreshConnection::AccessControl
  end

  test "forced master state" do
    @ac.access(true) do
      @ac.force_master_access do
        refute @ac.replica_access?
      end
    end
  end

  test "not effect outside" do
    @ac.access(true) do
      @ac.force_master_access {}
      assert @ac.replica_access?
    end
  end
end
