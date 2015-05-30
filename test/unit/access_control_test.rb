require_relative "../test_helper"

class AccessControlTest < Minitest::Test
  def setup
    @ac = FreshConnection::AccessControl
  end

  group ".access" do
    test "persisted first state(slave)" do
      ret = []
      @ac.access(true) do
        @ac.access(true) do
          ret << @ac.slave_access?
          @ac.access(false) do
            ret << @ac.slave_access?
          end
        end
      end

      assert ret.all?{|item| item}
    end

    test "persisted first state(master)" do
      ret = []
      @ac.access(false) do
        @ac.access(true) do
          ret << @ac.slave_access?
          @ac.access(false) do
            ret << @ac.slave_access?
          end
        end
      end

      assert !(ret.all?{|item| item})
    end

    test "outside is always master" do
      ret = []
      ret << @ac.slave_access?
      @ac.access(true){}
      ret << @ac.slave_access?

      assert !(ret.all?{|item| item})
    end
  end
end
