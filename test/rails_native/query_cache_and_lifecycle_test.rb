require "test_helper"
require "fresh_connection/executor_hook"

if FreshConnection::RailsReplica.supported?
  class RailsNativeQueryCacheAndLifecycleTest < Minitest::Test
    def setup
      super
      @original_put_aside = FreshConnection.put_aside
      @original_recovery = FreshConnection.recovery
      @original_retry_limit = FreshConnection.retry_limit
      ActiveRecord::Base.clear_query_caches_for_current_thread
    end

    def teardown
      FreshConnection.put_aside = @original_put_aside
      FreshConnection.recovery = @original_recovery
      FreshConnection.retry_limit = @original_retry_limit
      FreshConnection::RailsReplica.send(:reading_pools).each(&:release_connection)
      FreshConnection::RailsReplica.send(:writing_pools).each(&:release_connection)
      super
    end

    test "query cache works on replica reads via model and ActiveRecord::Base" do
      filename = File.join(__dir__, "../../log/sql.log")

      NativeAddress.cache do
        NativeAddress.find(1)
        NativeAddress.find(1)
        last_line = `tail -1 #{filename}`
        assert_match(/CACHE/, last_line)
      end

      ActiveRecord::Base.cache do
        NativeAddress.find(1)
        NativeAddress.find(1)
        last_line = `tail -1 #{filename}`
        assert_match(/CACHE/, last_line)
      end
    end

    test "ActiveRecord::Base.uncached disables reading pool query cache" do
      reading_pool = FreshConnection::RailsReplica.reading_pool_for(NativeAddress)
      ActiveRecord::Base.cache do
        assert reading_pool.query_cache_enabled
        ActiveRecord::Base.uncached do
          refute reading_pool.query_cache_enabled
        end
        assert reading_pool.query_cache_enabled
      end
    end

    if ActiveRecord::VERSION::MAJOR >= 8 || (ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR >= 2)
      test "ActiveRecord::Base.uncached(dirties: false) preserves reading pool query cache" do
        reading_pool = FreshConnection::RailsReplica.reading_pool_for(NativeAddress)
        filename = File.join(__dir__, "../../log/sql.log")

        ActiveRecord::Base.cache do
          NativeAddress.find(1)
          ActiveRecord::Base.uncached(dirties: false) do
            refute reading_pool.query_cache_enabled
            NativeAddress.find(1)
          end
          assert reading_pool.query_cache_enabled
          NativeAddress.find(1)
          last_line = `tail -1 #{filename}`
          assert_match(/CACHE/, last_line)
        end
      end
    end

    test "query cache is invalidated after master write" do
      old_pref = SecureRandom.hex(3)
      a = NativeFakeAddress.create!(prefecture: old_pref)

      NativeAddress.cache do
        new_pref = old_pref + "1"
        b = NativeFakeAddress.find(a.id)
        b.prefecture = new_pref
        b.save!

        address = NativeFakeAddress.find(a.id)
        assert_equal new_pref, address.prefecture
      end
    ensure
      a.destroy if a
    end

    test "put_aside! disconnects reading connection when enabled" do
      FreshConnection.put_aside = true
      conn = NativeUser.replica_connection
      conn.verify!
      assert conn.active?

      FreshConnection::ExecutorHook.complete
      refute conn.active?
    end

    test "put_aside! does not disconnect reading connection when disabled" do
      FreshConnection.put_aside = false
      conn = NativeUser.replica_connection
      conn.verify!
      assert conn.active?

      FreshConnection::ExecutorHook.complete
      assert conn.active?
    end

    test "put_aside! disconnects tracked idle reading connection after query" do
      FreshConnection.put_aside = true
      reading_pool = FreshConnection::RailsReplica.reading_pool_for(NativeUser)
      reading_pool.disconnect!

      assert_includes NativeUser.where(id: 1).first.name, "replica1"
      assert_equal 1, reading_pool.connections.size

      FreshConnection::ExecutorHook.complete
      assert_empty reading_pool.connections
    end

    test "put_aside! is safe under concurrent threads" do
      FreshConnection.put_aside = true
      FreshConnection::RailsReplica.send(:reading_pools).each(&:release_connection)
      FreshConnection::RailsReplica.send(:writing_pools).each(&:release_connection)
      errors = []
      threads = 5.times.map do
        Thread.new do
          3.times do
            NativeUser.where(id: 1).first
            FreshConnection::ExecutorHook.complete
            FreshConnection::RailsReplica.send(:writing_pools).each(&:release_connection)
          end
        rescue StandardError => e
          errors << e
        ensure
          FreshConnection::RailsReplica.send(:reading_pools).each(&:release_connection)
          FreshConnection::RailsReplica.send(:writing_pools).each(&:release_connection)
        end
      end
      threads.each(&:join)
      assert_empty errors
    end

    test "clear_all_replica_connections! disconnects native reading pools" do
      conn = NativeUser.replica_connection
      conn.verify!
      assert conn.active?

      ActiveRecord::Base.clear_all_replica_connections!
      refute conn.active?
    end

    test "RailsReplica.recovery? retries on ConnectionNotEstablished without stubbing" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 3
      attempts = 0

      raise_once = lambda { |*args, &block|
        if attempts == 0
          attempts += 1
          raise ActiveRecord::ConnectionNotEstablished, "replica down"
        end
        attempts += 1
      }

      FreshConnection::AccessControl.exception_or_super(:access, raise_once) do
        assert NativeUser.take
      end
      assert_equal 2, attempts
    end

    test "RailsReplica.recovery? does not retry SQL syntax error on healthy connection" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 3
      NativeUser.where(id: 1).first # ensure healthy replica

      attempts = 0
      assert_raises(ActiveRecord::StatementInvalid) do
        FreshConnection::AccessControl.manage_access(model: NativeUser, replica_access: true) do
          attempts += 1
          raise ActiveRecord::StatementInvalid, "syntax error"
        end
      end
      assert_equal 1, attempts
    end

    test "with_master does not retry or invoke recovery? on errors" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 3
      attempts = 0
      recovery_called = false

      FreshConnection::AccessControl.stub(:recovery?, ->(_target) { recovery_called = true; true }) do
        assert_raises(ActiveRecord::StatementInvalid) do
          NativeUser.with_master do
            attempts += 1
            raise ActiveRecord::StatementInvalid, "unique violation"
          end
        end
      end

      assert_equal 1, attempts
      refute recovery_called
    end

    test "retry_limit = 1 does not invoke recovery?" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 1
      recovery_called = false

      FreshConnection::AccessControl.stub(:recovery?, ->(_target) { recovery_called = true; true }) do
        assert_raises(ActiveRecord::ConnectionNotEstablished) do
          FreshConnection::AccessControl.manage_access(model: NativeUser, replica_access: true) do
            raise ActiveRecord::ConnectionNotEstablished, "replica down"
          end
        end
      end

      refute recovery_called
    end

    test "nested manage_access does not multiply retries or recover unrelated outer model" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 3
      inner_attempts = 0
      recovered_targets = []

      FreshConnection::AccessControl.stub(:recovery?, ->(target) { recovered_targets << target; true }) do
        assert_raises(ActiveRecord::ConnectionNotEstablished) do
          FreshConnection::AccessControl.manage_access(model: NativeUser, replica_access: true) do
            FreshConnection::AccessControl.manage_access(model: NativeTel, replica_access: true) do
              inner_attempts += 1
              raise ActiveRecord::ConnectionNotEstablished, "replica2 down"
            end
          end
        end
      end

      assert_equal 3, inner_attempts
      assert_equal [NativeTel, NativeTel], recovered_targets
    end

    test "with_master on another model clears prevent_writes from outer reading block" do
      created = nil
      NativeUser.all.manage_access do
        NativeTel.with_master do
          created = NativeFakeAddress.create!(prefecture: "Tokyo (write test)")
        end
      end
      assert created && created.persisted?
    ensure
      created.destroy if created
    end

    test "recovery stops when disabled" do
      count = 0
      raise_once = lambda { |*args, &block|
        if count == 0
          count += 1
          raise ActiveRecord::ConnectionNotEstablished, "replica down"
        end
      }

      FreshConnection.recovery = false
      FreshConnection::AccessControl.exception_or_super(:access, raise_once) do
        FreshConnection::AccessControl.stub(:recovery?, true) do
          assert_raises(ActiveRecord::ConnectionNotEstablished) do
            NativeUser.take
          end
        end
      end
    end

    test "ActiveSupport::Executor.wrap automatically puts aside reading connection via ExecutorHook" do
      require "active_support/executor"
      executor_class = Class.new(ActiveSupport::Executor)
      executor_class.register_hook(FreshConnection::ExecutorHook)
      reading_pool = FreshConnection::RailsReplica.reading_pool_for(NativeUser)

      FreshConnection.put_aside = true
      reading_pool.disconnect!
      executor_class.wrap do
        assert_includes NativeUser.where(id: 1).first.name, "replica1"
        assert_equal 1, reading_pool.connections.size
      end
      assert_empty reading_pool.connections

      FreshConnection.put_aside = false
      executor_class.wrap do
        assert_includes NativeUser.where(id: 1).first.name, "replica1"
      end
      assert_equal 1, reading_pool.connections.size
    end

    test "RailsReplica.recovery? discards real dead idle reading connection and reconnects" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 3
      reading_pool = FreshConnection::RailsReplica.reading_pool_for(NativeUser)
      reading_pool.disconnect!

      assert_includes NativeUser.where(id: 1).first.name, "replica1"
      reading_pool.release_connection

      idle_conn = reading_pool.connections.first
      assert idle_conn
      refute idle_conn.in_use?

      close_raw_connection!(idle_conn)
      refute connection_active?(idle_conn)

      assert FreshConnection::RailsReplica.recovery?(
        NativeUser,
        exception: ActiveRecord::StatementInvalid.new("server closed connection")
      )
      refute_includes reading_pool.connections, idle_conn
      assert_includes NativeUser.where(id: 1).first.name, "replica1"
    end

    test "RailsReplica.recovery? discards real dead leased reading connection and query recovers end-to-end" do
      FreshConnection.recovery = true
      FreshConnection.retry_limit = 3
      reading_pool = FreshConnection::RailsReplica.reading_pool_for(NativeUser)

      conn = NativeUser.replica_connection
      conn.verify!
      close_raw_connection!(conn)
      refute connection_active?(conn)

      assert FreshConnection::RailsReplica.recovery?(
        NativeUser,
        exception: ActiveRecord::StatementInvalid.new("lost connection")
      )
      refute_includes reading_pool.connections, conn
      assert_includes NativeUser.where(id: 1).first.name, "replica1"

      # Also verify end-to-end query execution after closing the leased socket directly
      conn2 = NativeUser.replica_connection
      conn2.verify!
      close_raw_connection!(conn2)
      assert_includes NativeUser.where(id: 1).first.name, "replica1"
    end

    private

    def connection_active?(conn)
      conn.active?
    rescue StandardError
      false
    end

    def close_raw_connection!(conn)
      raw = conn.instance_variable_get(:@raw_connection) || conn.instance_variable_get(:@connection)
      raw.close if raw && raw.respond_to?(:close)
    end
  end
end
