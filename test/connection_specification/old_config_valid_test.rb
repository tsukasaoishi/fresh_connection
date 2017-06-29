require "test_helper"

class OldConfigValidTest < Minitest::Test
  def check_error_output(expected=nil, &block)
    out, err = capture_io do
      block.call
    end

    assert_empty out

    if expected
      assert_match expected, err
    else
      assert_empty err
    end
  end

  def build_spec_assert_output spec_name, output
    name = SecureRandom.hex(5)
    config = yield name
    config[:adapter] = "mysql2"

    s = FreshConnection::ConnectionSpecification.new(spec_name)
    s.stub(:base_config, config) do
      check_error_output(output) do
        assert_equal name, s.spec.config[:username]
      end
    end
  end

  unless ENV.key?('DATABASE_REPLICA_URL')
    test "use :slave if group is :replica and spec has :slave and spec has not :replica" do
      build_spec_assert_output(:replica, /deprecated/) do |name|
        {
          username: "other name",
          slave: { username: name }
        }
      end
    end

    test "use :replica if group is :replica and spec has :slave and spec has :replica" do
      build_spec_assert_output(:replica, '') do |name|
        { username: "other name",
          slave:    { username: "bad name" },
          replica:  { username: name }}
      end
    end
  end
end
