require "test_helper"

class RecoveryTest < Minitest::Test
  test "enable recovery" do
    count = 0
    raise_exception = lambda {|*args, &block|
      if count == 0
        count += 1
        raise ActiveRecord::StatementInvalid, "hoge"
      end
    }

    FreshConnection::AccessControl.exception_or_super(:access, raise_exception) do
      FreshConnection::AccessControl.stub(:recovery?, true) do
        assert User.take
      end
    end
  end

  test "raise exception when retry over" do
    raise_exception = lambda {|*args|
      raise ActiveRecord::StatementInvalid, "hoge"
    }

    FreshConnection::AccessControl.stub(:access, raise_exception) do
      FreshConnection::AccessControl.stub(:recovery?, true) do
        assert_raises(ActiveRecord::StatementInvalid) do
          User.take
        end
      end
    end
  end

  test "raise exception when conection active" do
    count = 0
    raise_exception = lambda {|*args, &block|
      if count == 0
        count += 1
        raise ActiveRecord::StatementInvalid, "hoge"
      end
    }

    FreshConnection::AccessControl.exception_or_super(:access, raise_exception) do
      FreshConnection::AccessControl.stub(:recovery?, false) do
        assert_raises(ActiveRecord::StatementInvalid) do
          User.take
        end
      end
    end
  end

  test "enable recovery (activerecord >= 6.1)" do
    count = 0
    raise_exception = lambda {|*args, &block|
      if count == 0
        count += 1
        raise ActiveRecord::ConnectionNotEstablished, "hoge"
      end
    }

    FreshConnection::AccessControl.exception_or_super(:access, raise_exception) do
      FreshConnection::AccessControl.stub(:recovery?, true) do
        assert User.take
      end
    end
  end

  test "raise exception when retry over (activerecord >= 6.1)" do
    raise_exception = lambda {|*args|
      raise ActiveRecord::ConnectionNotEstablished, "hoge"
    }

    FreshConnection::AccessControl.stub(:access, raise_exception) do
      FreshConnection::AccessControl.stub(:recovery?, true) do
        assert_raises(ActiveRecord::ConnectionNotEstablished) do
          User.take
        end
      end
    end
  end

  test "raise exception when conection active (activerecord >= 6.1)" do
    count = 0
    raise_exception = lambda {|*args, &block|
      if count == 0
        count += 1
        raise ActiveRecord::ConnectionNotEstablished, "hoge"
      end
    }

    FreshConnection::AccessControl.exception_or_super(:access, raise_exception) do
      FreshConnection::AccessControl.stub(:recovery?, false) do
        assert_raises(ActiveRecord::ConnectionNotEstablished) do
          User.take
        end
      end
    end
  end
end
