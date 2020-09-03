require "test_helper"

class AccessTest < Minitest::Test
  def setup
    super
    @ac = FreshConnection::AccessControl
  end

  test "persisted first state(replica)" do
    model = MiniTest::Mock.new
    model.expect(:reading_role, :reading)
    model.expect(:connected_to, nil, [{role: :reading}])

    ret = []
    @ac.send(:access, true, model: model) do
      @ac.send(:access, true, model: model) do
        ret << @ac.replica_access?
        @ac.send(:access, false, model: model) do
          ret << @ac.replica_access?
        end
      end
    end

    assert ret.all?{|item| item}
  end

  test "persisted first state(master)" do
    ret = []
    @ac.send(:access, false, model: nil) do
      @ac.send(:access, true, model: nil) do
        ret << @ac.replica_access?
        @ac.send(:access, false, model: nil) do
          ret << @ac.replica_access?
        end
      end
    end

    refute ret.all?{|item| item}
  end

  test "outside is always master" do
    model = MiniTest::Mock.new
    model.expect(:reading_role, :reading)
    model.expect(:connected_to, nil, [{role: :reading}])

    ret = []
    ret << @ac.replica_access?
    @ac.send(:access, true, model: model) {}
    ret << @ac.replica_access?

    refute ret.all?{|item| item}
  end
end
