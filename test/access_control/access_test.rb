require "test_helper"

class AccessTest < Minitest::Test
  def setup
    super
    @ac = FreshConnection::AccessControl
  end

  test "persisted first state(replica)" do
    ret = []
    @ac.access(true) do
      @ac.access(true) do
        ret << @ac.replica_access?
        @ac.access(false) do
          ret << @ac.replica_access?
        end
      end
    end

    assert ret.all?{|item| item}
  end

  test "persisted first state(master)" do
    ret = []
    @ac.access(false) do
      @ac.access(true) do
        ret << @ac.replica_access?
        @ac.access(false) do
          ret << @ac.replica_access?
        end
      end
    end

    refute ret.all?{|item| item}
  end

  test "outside is always master" do
    ret = []
    ret << @ac.replica_access?
    @ac.access(true){}
    ret << @ac.replica_access?

    refute ret.all?{|item| item}
  end
end
