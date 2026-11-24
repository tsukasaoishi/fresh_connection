require "test_helper"

if FreshConnection::RailsReplica.supported?
  class RailsNativeAccessToReplicaTest < Minitest::Test
    def setup
      super
      @user = NativeUser.where(id: 1).first
    end

    test "uses rails native replica mode" do
      assert FreshConnection::RailsReplica.use_rails_replica?(NativeUser)
      assert FreshConnection::RailsReplica.use_rails_replica?(NativeTel)
      refute FreshConnection::RailsReplica.use_rails_replica?(User)
      refute FreshConnection::RailsReplica.use_rails_replica?(NativeUnreplicatedUser)
    end

    test "replica_spec_name returns Rails reading db_config name" do
      assert_equal "replica1", NativeUser.replica_spec_name
      assert_equal "replica2", NativeTel.replica_spec_name
    end

    test "replica_connection returns reading pool adapter" do
      adapter = ActiveRecord::Base.connection_db_config.adapter
      case adapter
      when "mysql2"
        assert_kind_of ActiveRecord::ConnectionAdapters::Mysql2Adapter, NativeUser.replica_connection
      when "trilogy"
        assert_kind_of ActiveRecord::ConnectionAdapters::TrilogyAdapter, NativeUser.replica_connection
      when "postgresql"
        assert_kind_of ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, NativeUser.replica_connection
      end
    end

    test "select from NativeUser accesses replica1" do
      data = [
        @user.name,
        NativeUser.find(1).name,
        NativeUser.find_by(id: 1).name,
        NativeAddress.first.native_user.name,
        NativeTel.first.native_user.name
      ]

      assert data.all? { |n| n.include?("replica1") }
    end

    test "select from NativeAddress accesses replica1" do
      data = [
        NativeAddress.first.prefecture,
        @user.native_address.prefecture
      ]

      assert data.all? { |n| n.include?("replica1") }
    end

    test "select from NativeTel accesses replica2" do
      data = [
        NativeTel.first.number,
        @user.native_tels.first.number
      ]

      assert data.all? { |n| n.include?("replica2") }
    end

    test "select with includes accesses each model's respective replica" do
      user = NativeUser.where(id: 1).includes(:native_tels, :native_address).first
      assert_includes user.name, "replica1"
      assert_includes user.native_address.prefecture, "replica1"
      assert_includes user.native_tels.first.number, "replica2"
    end

    test "select with join accesses replica1" do
      name = NativeUser.joins(:native_address).where("addresses.user_id = 1").where(id: 1).first.name
      assert_includes name, "replica1"
    end

    test "pluck accesses replica1" do
      assert_includes NativeUser.where(id: 1).pluck(:name).first, "replica1"
    end

    test "pluck returns empty array when result is empty" do
      assert_empty NativeUser.limit(0).pluck(:name)
    end

    test "count accesses replica1" do
      assert_equal 2, NativeUser.where(name: "Other").count
    end

    test "reload accesses replica1" do
      assert_includes @user.reload.name, "replica1"
    end

    test "exists? accesses replica1" do
      assert NativeUser.where(id: 3).exists?
    end

    test "find_each accesses replica1" do
      names = []
      NativeUser.where(id: 1).find_each { |u| names << u.name }
      assert_equal ["Tsukasa (replica1)"], names
    end

    if ActiveRecord::Relation.method_defined?(:pick)
      test "pick accesses replica1 and read_master.pick accesses master" do
        assert_includes NativeUser.where(id: 1).pick(:name), "replica1"
        assert_includes NativeUser.where(id: 1).read_master.pick(:name), "master"
      end
    end

    test "ids and calculate methods (sum, maximum) access replica1 and respect read_master" do
      assert_equal [1, 2, 3], NativeUser.order(:id).ids
      assert_equal [1, 2], NativeUser.read_master.order(:id).ids
      assert_equal 6, NativeUser.sum(:id)
      assert_equal 3, NativeUser.read_master.sum(:id)
      assert_equal 3, NativeUser.maximum(:id)
      assert_equal 2, NativeUser.read_master.maximum(:id)
    end

    if ActiveRecord::Relation.private_method_defined?(:compute_cache_version)
      test "cache_version accesses replica1 and respects read_master" do
        original = NativeUser.collection_cache_versioning
        NativeUser.collection_cache_versioning = true
        assert NativeUser.all.cache_version.start_with?("3-")
        assert NativeUser.read_master.cache_version.start_with?("2-")
      ensure
        NativeUser.collection_cache_versioning = original
      end
    end

    test "preload and eager_load access respective replicas and respect read_master" do
      user = NativeUser.where(id: 1).preload(:native_tels, :native_address).first
      assert_includes user.name, "replica1"
      assert_includes user.native_address.prefecture, "replica1"
      assert_includes user.native_tels.first.number, "replica2"

      eager_user = NativeUser.where(id: 1).eager_load(:native_address).first
      assert_includes eager_user.name, "replica1"
      assert_includes eager_user.native_address.prefecture, "replica1"

      master_eager_user = NativeUser.where(id: 1).eager_load(:native_address).read_master.first
      assert_includes master_eager_user.name, "master"
      assert_includes master_eager_user.native_address.prefecture, "master"
    end

    if ActiveRecord::Relation.method_defined?(:load_async)
      test "load_async accesses replica1 and stays scheduled when async_query_executor is enabled" do
        if ActiveRecord.respond_to?(:async_query_executor=)
          original_executor = ActiveRecord.async_query_executor
          ActiveRecord.async_query_executor = :global_thread_pool
          begin
            rel = NativeUser.where(id: 1).load_async
            assert rel.scheduled? || rel.loaded?
            assert_includes rel.to_a.first.name, "replica1"
          ensure
            ActiveRecord.async_query_executor = original_executor
          end
        else
          users = NativeUser.where(id: 1).load_async.to_a
          assert_includes users.first.name, "replica1"
        end
      end
    end
  end
end
