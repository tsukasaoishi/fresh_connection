require "test_helper"

class ForceMasterAccessTest < Minitest::Test

  def setup
    super
    @ac = FreshConnection::AccessControl
  end

  test "forced master state" do
    model = MiniTest::Mock.new
    model.expect(:reading_role, :reading)
    model.expect(:connected_to, nil, [{role: :reading}])

    @ac.send(:access, true, model: model) do
      @ac.send(:force_master_access) do
        refute @ac.replica_access?
      end
    end
  end

  test "not effect outside" do
    model = MiniTest::Mock.new
    model.expect(:reading_role, :reading)
    model.expect(:connected_to, nil, [{role: :reading}])

    @ac.send(:access, true, model: model) do
      @ac.send(:force_master_access) {}
      assert @ac.replica_access?
    end
  end
end
