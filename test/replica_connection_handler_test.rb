require "test_helper"

class ReplicaConnectionHandlerTest < Minitest::Test
  test "#establish_connection create connection manager object" do
    h = FreshConnection::ReplicaConnectionHandler.instance
    obj = SecureRandom.hex(10)

    FreshConnection::ConnectionManager.stub(:new, obj) do
      h.establish_connection(:tsuka)
      owner_to_pool = h.send(:owner_to_pool)
      assert_equal owner_to_pool["tsuka"], obj
    end
  end
end

