require "test_helper"
require "open3"
require "rbconfig"

if ActiveRecord::Base.respond_to?(:primary_abstract_class)
  class PrimaryAbstractClassNativeTest < Minitest::Test
    test "pure Rails 7+ primary_abstract_class with connects_to works without legacy config or deprecation warnings" do
      lib_dir = File.expand_path("../../lib", __dir__)
      script = <<~'RUBY'
        require "logger"
        require "active_support"
        require "active_support/executor"
        require "fresh_connection/deprecator"

        warnings = []
        FreshConnection.deprecator.behavior = ->(message, *_args) { warnings << message }

        require "active_record"
        require "fresh_connection"
        require "fresh_connection/executor_hook"

        def resolve_url(url)
          ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(url).to_hash.transform_keys(&:to_s)
        end

        env_name = defined?(ActiveRecord::ConnectionHandling::DEFAULT_ENV) ? ActiveRecord::ConnectionHandling::DEFAULT_ENV.call : "default_env"
        configs = {
          "primary" => resolve_url(ENV.fetch("DATABASE_URL")),
          "replica1" => resolve_url(ENV.fetch("DATABASE_REPLICA1_URL")).merge("replica" => true),
          "replica2" => resolve_url(ENV.fetch("DATABASE_REPLICA2_URL")).merge("replica" => true)
        }
        ActiveRecord::Base.configurations = { env_name => configs }

        class ApplicationRecord < ActiveRecord::Base
          primary_abstract_class
          connects_to database: { writing: :primary, reading: :replica1 }
        end

        class PureUser < ApplicationRecord
          self.table_name = :users
          has_one :pure_address, foreign_key: :user_id
        end

        class PureAddress < ApplicationRecord
          self.table_name = :addresses
          belongs_to :pure_user, foreign_key: :user_id
        end

        class SecondaryRecord < ActiveRecord::Base
          self.abstract_class = true
          connects_to database: { writing: :primary, reading: :replica2 }
        end

        class PureTel < SecondaryRecord
          self.table_name = :tels
        end

        class UnreplicatedRecord < ActiveRecord::Base
          self.abstract_class = true
          connects_to database: { writing: :primary }
        end

        class PureUnreplicatedUser < UnreplicatedRecord
          self.table_name = :users
        end

        def assert_true(cond, msg)
          abort "FAIL: #{msg}" unless cond
        end

        # Mode detection
        assert_true FreshConnection::RailsReplica.use_rails_replica?(PureUser), "PureUser should use rails replica"
        assert_true FreshConnection::RailsReplica.use_rails_replica?(PureTel), "PureTel should use rails replica"
        assert_true !FreshConnection::RailsReplica.use_rails_replica?(PureUnreplicatedUser), "PureUnreplicatedUser should not use rails replica"
        assert_true !FreshConnection::RailsReplica.legacy_replica_enabled?(PureUser), "PureUser should not enable legacy replica"
        assert_true !FreshConnection::RailsReplica.legacy_replica_enabled?(PureUnreplicatedUser), "PureUnreplicatedUser should not enable legacy replica"

        # Reads route to respective replicas / master
        assert_true PureUser.where(id: 1).first.name.include?("replica1"), "PureUser should read replica1"
        assert_true PureUser.find(1).name.include?("replica1"), "PureUser.find should read replica1"
        assert_true PureTel.first.number.include?("replica2"), "PureTel should read replica2"
        assert_true PureUnreplicatedUser.where(id: 1).first.name.include?("master"), "PureUnreplicatedUser should read master"

        # connected_to(role: :writing) on ApplicationRecord and ActiveRecord::Base
        ApplicationRecord.connected_to(role: :writing) do
          assert_true PureUser.where(id: 1).first.name.include?("master"), "ApplicationRecord.connected_to(:writing) should route PureUser to master"
          unless FreshConnection::RailsReplica.send(:legacy_connection_handling?)
            assert_true PureTel.first.number.include?("replica2"), "ApplicationRecord.connected_to(:writing) should keep PureTel on replica2"
          end
        end

        ActiveRecord::Base.connected_to(role: :writing) do
          assert_true PureUser.where(id: 1).first.name.include?("master"), "Base.connected_to(:writing) should route PureUser to master"
          assert_true PureTel.first.number.include?("master"), "Base.connected_to(:writing) should route PureTel to master"
        end

        # Transaction, with_master, read_master
        PureUser.transaction do
          assert_true PureUser.find(1).name.include?("master"), "transaction should route PureUser to master"
          assert_true PureTel.first.number.include?("master"), "transaction sharing primary DB should route PureTel to master"
        end

        PureUser.with_master do
          assert_true PureUser.find(1).name.include?("master"), "with_master should route PureUser to master"
        end

        assert_true PureUser.read_master.where(id: 1).first.name.include?("master"), "read_master should route PureUser to master"

        # Write CRUD
        created = nil
        begin
          created = PureAddress.create!(user_id: 1, prefecture: "PureNative (write)")
          assert_true created.persisted?, "PureAddress.create! should persist"
          assert_true PureAddress.read_master.find(created.id).prefecture == "PureNative (write)", "should read back from master"
          assert_true !PureAddress.where(id: created.id).exists?, "should not exist on replica1"
        ensure
          created.destroy if created && created.persisted?
        end

        # ActiveSupport::Executor hook auto put_aside!
        FreshConnection::ExecutorHook.install_executor_hooks
        reading_pool = FreshConnection::RailsReplica.reading_pool_for(PureUser)
        reading_pool.disconnect!
        ActiveSupport::Executor.wrap do
          assert_true PureUser.where(id: 1).first.name.include?("replica1"), "Executor wrap read should hit replica1"
          assert_true reading_pool.connections.size == 1, "reading_pool should have 1 connection before wrap completes"
        end
        assert_true reading_pool.connections.empty?, "Executor wrap completion should put aside reading connection"

        # Zero deprecation warnings in pure Rails 7+ native configuration
        assert_true warnings.empty?, "Expected 0 deprecation warnings, got: #{warnings.inspect}"

        puts "PRIMARY_ABSTRACT_CLASS_OK"
      RUBY

      stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-I#{lib_dir}", "-e", script)
      assert status.success?, "Primary abstract class subprocess failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
      assert_includes stdout, "PRIMARY_ABSTRACT_CLASS_OK"
    end
  end
end
