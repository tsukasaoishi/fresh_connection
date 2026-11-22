require "test_helper"

if FreshConnection::RailsReplica.supported?
  class RailsNativeAccessToMasterTest < Minitest::Test
    def setup
      super
      @user = NativeUser.where(id: 1).first
    end

    test "in transaction accesses master across models sharing primary writing db" do
      NativeUser.transaction do
        assert_includes @user.name, "replica1"
        data = [
          NativeUser.find(1).name,
          NativeAddress.first.native_user.name,
          NativeAddress.first.prefecture,
          NativeTel.first.number,
          NativeTel.first.native_user.name,
          @user.native_address.prefecture,
          @user.native_tels.first.number,
          NativeUser.joins(:native_address).where(id: 1).where("addresses.user_id = 1").first.name,
          NativeUser.where(id: 1).pluck(:name).first,
          @user.reload.name
        ]
        assert data.all? { |n| n.include?("master") }
        assert_equal 1, NativeUser.where(name: "Other").count
        refute NativeUser.where(id: 3).exists?
      end
    end

    test "in with_master accesses master" do
      NativeUser.with_master do
        assert_includes @user.name, "replica1"
        data = [
          NativeUser.find(1).name,
          NativeAddress.first.native_user.name,
          NativeAddress.first.prefecture,
          NativeTel.first.number,
          NativeTel.first.native_user.name,
          @user.native_address.prefecture,
          @user.native_tels.first.number,
          NativeUser.joins(:native_address).where(id: 1).where("addresses.user_id = 1").first.name,
          NativeUser.where(id: 1).pluck(:name).first,
          @user.reload.name
        ]
        assert data.all? { |n| n.include?("master") }
        assert_equal 1, NativeUser.where(name: "Other").count
        refute NativeUser.where(id: 3).exists?
      end
    end

    test "specify read_master accesses master" do
      data = [
        NativeAddress.read_master.first.prefecture,
        NativeAddress.includes(:native_user).read_master.first.native_user.name,
        NativeTel.read_master.first.number,
        NativeTel.includes(:native_user).read_master.first.native_user.name,
        @user.native_tels.read_master.first.number,
        NativeUser.where(id: 1).includes(:native_tels).read_master.first.native_tels.first.number,
        NativeUser.where(id: 1).includes(:native_address).read_master.first.native_address.prefecture,
        NativeUser.where(id: 1).joins(:native_address).where("addresses.user_id = 1").read_master.first.name,
        NativeUser.where(id: 1).read_master.pluck(:name).first
      ]
      assert data.all? { |n| n.include?("master") }
      assert_equal 1, NativeUser.where(name: "Other").read_master.count
      refute NativeUser.read_master.where(id: 3).exists?
    end

    test "merge with read_master accesses master" do
      prefecture = NativeAddress.all.merge(NativeAddress.read_master).first.prefecture
      assert_includes prefecture, "master"
    end

    test "master_db_only model always accesses master even when preloaded from replica query" do
      assert_includes NativeMasterOnlyAddress.first.prefecture, "master"

      user = NativeUser.where(id: 1).includes(:native_master_only_addresses).first
      assert_includes user.name, "replica1"
      assert_includes user.native_master_only_addresses.first.prefecture, "master"
    end

    test "nested read_master scope inside includes accesses master while outer model stays on replica" do
      user = NativeUser.where(id: 1).includes(:native_read_master_addresses).first
      assert_includes user.name, "replica1"
      assert_includes user.native_read_master_addresses.first.prefecture, "master"
    end

    test "nested with_master and connected_to(role: :writing) inside replica block access master" do
      NativeUser.all.manage_access do
        assert_includes NativeUser.where(id: 1).first.name, "replica1"

        NativeUser.with_master do
          assert_includes NativeUser.where(id: 1).first.name, "master"
        end

        ActiveRecord::Base.connected_to(role: :writing) do
          assert_includes NativeUser.where(id: 1).first.name, "master"
        end

        assert_includes NativeUser.where(id: 1).first.name, "replica1"
      end
    end

    test "explicit Rails connected_to(role: :writing) is respected" do
      ActiveRecord::Base.connected_to(role: :writing) do
        assert_includes NativeUser.where(id: 1).first.name, "master"
        assert_includes NativeTel.first.number, "master"
      end

      unless FreshConnection::RailsReplica.send(:legacy_connection_handling?)
        NativeRecord.connected_to(role: :writing) do
          assert_includes NativeUser.where(id: 1).first.name, "master"
          assert_includes NativeTel.first.number, "replica2"
        end
      end
    end

    test "read_master inside connected_to(role: :reading) accesses master" do
      target = FreshConnection::RailsReplica.send(:connected_to_target, NativeUser)
      target.connected_to(role: :reading) do
        assert_includes NativeUser.where(id: 1).first.name, "replica1"
        assert_includes NativeUser.where(id: 1).read_master.first.name, "master"
      end
    end

    test "model without reading role works standalone and when preloaded from replica query" do
      assert_includes NativeUnreplicatedUser.where(id: 1).first.name, "master"

      user = NativeUser.where(id: 1).includes(:native_unreplicated_addresses).first
      assert_includes user.name, "replica1"
      assert_includes user.native_unreplicated_addresses.first.prefecture, "master"
    end

    test "calling replica_spec_name does not pollute explicit_fresh_connection?" do
      refute NativeUnreplicatedUser.explicit_fresh_connection?
      NativeUnreplicatedUser.replica_spec_name
      refute NativeUnreplicatedUser.explicit_fresh_connection?
      assert_includes NativeUnreplicatedUser.where(id: 1).first.name, "master"
    end

    test "lock query accesses master standalone and inside replica block" do
      assert_includes NativeUser.lock.where(id: 1).first.name, "master"

      NativeUser.all.manage_access do
        assert_includes NativeUser.lock.where(id: 1).first.name, "master"
      end
    end

    test "top-level CRUD operations write to master without ReadOnlyError while reads stay on replica" do
      created = nil
      created2 = nil
      created = NativeAddress.create!(user_id: 1, prefecture: "Osaka (write)")
      assert created.persisted?
      assert_equal "Osaka (write)", NativeAddress.read_master.find(created.id).prefecture
      refute NativeAddress.where(id: created.id).exists?

      created.update!(prefecture: "Kyoto (write)")
      assert_equal "Kyoto (write)", NativeAddress.read_master.find(created.id).prefecture

      NativeAddress.where(id: created.id).update_all(prefecture: "Kobe (write)")
      assert_equal "Kobe (write)", NativeAddress.read_master.find(created.id).prefecture

      created.destroy!
      refute NativeAddress.read_master.where(id: created.id).exists?
      created = nil

      created2 = NativeAddress.find_or_create_by!(user_id: 1, prefecture: "Sapporo (write)")
      assert created2.persisted?
      assert_equal "Sapporo (write)", NativeAddress.read_master.find(created2.id).prefecture

      NativeAddress.where(id: created2.id).delete_all
      refute NativeAddress.read_master.where(id: created2.id).exists?
      created2 = nil
    ensure
      created.destroy if created && created.persisted?
      created2.destroy if created2 && created2.persisted?
    end

    test "SELECT inside before_save and after_create callbacks accesses master via implicit transaction" do
      observed = []
      callback_address_class = Class.new(NativeRecord) do
        def self.name
          "NativeCallbackAddress"
        end
        self.table_name = :addresses
        before_save -> { observed << [:before_save, NativeUser.where(id: 1).first.name] }
        after_create -> { observed << [:after_create, NativeUser.find(1).name] }
      end

      created = callback_address_class.create!(user_id: 1, prefecture: "Callback (write)")
      assert_equal 2, observed.size
      assert_equal :before_save, observed[0][0]
      assert_includes observed[0][1], "master"
      assert_equal :after_create, observed[1][0]
      assert_includes observed[1][1], "master"
    ensure
      NativeAddress.where(id: created.id).delete_all if created && created.persisted?
    end

    test "StatementCache find and find_by switch cleanly across repeated alternating roles" do
      assert_includes NativeUser.find(1).name, "replica1"
      assert_includes NativeUser.find_by(id: 1).name, "replica1"

      NativeUser.with_master do
        assert_includes NativeUser.find(1).name, "master"
        assert_includes NativeUser.find_by(id: 1).name, "master"
      end

      assert_includes NativeUser.read_master.find(1).name, "master"
      assert_includes NativeUser.read_master.find_by(id: 1).name, "master"

      NativeUser.transaction do
        assert_includes NativeUser.find(1).name, "master"
        assert_includes NativeUser.find_by(id: 1).name, "master"
      end

      assert_includes NativeUser.find(1).name, "replica1"
      assert_includes NativeUser.find_by(id: 1).name, "replica1"
    end

    test "exceptions inside with_master, connected_to, manage_access, and transaction do not leak routing state" do
      assert_raises(RuntimeError) { NativeUser.with_master { raise "boom" } }
      refute FreshConnection::AccessControl.managed?
      assert_includes NativeUser.where(id: 1).first.name, "replica1"

      assert_raises(RuntimeError) { ActiveRecord::Base.connected_to(role: :writing) { raise "boom" } }
      refute FreshConnection::RailsReplica.explicitly_connected_to_writing?(NativeUser)
      assert_includes NativeUser.where(id: 1).first.name, "replica1"

      assert_raises(RuntimeError) { NativeUser.all.manage_access { raise "boom" } }
      refute FreshConnection::AccessControl.managed?
      assert_includes NativeUser.where(id: 1).first.name, "replica1"

      assert_raises(RuntimeError) { NativeUser.transaction { raise "boom" } }
      refute FreshConnection::RailsReplica.in_transaction?(NativeUser)
      assert_includes NativeUser.where(id: 1).first.name, "replica1"
    end

    test "transaction on a different writing database does not force primary models off replica" do
      NativeSecondaryDbUser.transaction do
        assert FreshConnection::RailsReplica.in_transaction?(NativeSecondaryDbUser)
        refute FreshConnection::RailsReplica.in_transaction?(NativeUser)
        assert_includes NativeSecondaryDbUser.where(id: 1).first.name, "replica2"
        assert_includes NativeUser.where(id: 1).first.name, "replica1"
      end
    end
  end
end
