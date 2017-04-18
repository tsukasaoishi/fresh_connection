require "test_helper"

class OldConfigValidTest < Minitest::Test
  test "use :slave if group is :replica and spec has :slave and spec has not :replica" do
    name = SecureRandom.hex(5)
    f = FreshConnection::ConnectionFactory.new(:replica)
    f.define_singleton_method(:ar_spec) do
      Struct.new(:config).new(username: "name", slave: { username: name })
    end

    assert_equal f.__send__(:spec)[:username], name
  end

  test "use :replica if group is :replica and spec has :slave and spec has :replica" do
    name = SecureRandom.hex(5)
    f = FreshConnection::ConnectionFactory.new(:replica)
    f.define_singleton_method(:ar_spec) do
      Struct.new(:config).new(
        username: "name",
        slave: { username: "bad_name" },
        replica: { username: name }
      )
    end

    assert_equal f.__send__(:spec)[:username], name
  end

end
