require "test_helper"

class ForceMasterAccessTest < Minitest::Test

  def setup
    super
    @ac = FreshConnection::AccessControl
  end

  test "forced master state" do
    @ac.send(:access, true) do
      @ac.send(:force_master_access) do
        refute @ac.replica_access?
      end
    end
  end

  test "not effect outside" do
    @ac.send(:access, true) do
      @ac.send(:force_master_access) {}
      assert @ac.replica_access?
    end
  end
end
