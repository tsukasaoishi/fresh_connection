require "test_helper"

class RecoveryTest < Minitest::Test
  test "enable recovery" do
    count = 0
    raise_exception = lambda {|*args|
      if count == 0
        count += 1
        raise ActiveRecord::StatementInvalid, "hoge"
      end
    }

    FreshConnection::AccessControl.stub(:access, raise_exception) do
      User.stub(:replica_connection_recovery?, true) do
        assert User.take
      end
    end
  end

  test "raise exception when retry over" do
    raise_exception = lambda {|*args|
      raise ActiveRecord::StatementInvalid, "hoge"
    }

    FreshConnection::AccessControl.stub(:access, raise_exception) do
      User.stub(:replica_connection_recovery?, true) do
        assert_raises(ActiveRecord::StatementInvalid) do
          User.take
        end
      end
    end
  end

  test "raise exception when conection active" do
    count = 0
    raise_exception = lambda {|*args|
      if count == 0
        count += 1
        raise ActiveRecord::StatementInvalid, "hoge"
      end
    }

    FreshConnection::AccessControl.stub(:access, raise_exception) do
      User.stub(:replica_connection_recovery?, false) do
        assert_raises(ActiveRecord::StatementInvalid) do
          User.take
        end
      end
    end
  end
end
