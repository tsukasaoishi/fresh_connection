require "test_helper"
require "open3"
require "rbconfig"

class RailtieTest < Minitest::Test
  test "railtie registers deprecator and ActiveSupport::Executor hook automatically" do
    lib_dir = File.expand_path("../lib", __dir__)
    script = <<~'RUBY'
      require "logger"
      require "active_support"
      require "active_support/deprecation"
      require "active_support/executor"

      module Rails
        class Railtie
          @initializers = []

          class << self
            attr_reader :initializers

            def initializer(name, opts = {}, &block)
              @initializers << { name: name, opts: opts, block: block }
            end
          end
        end
      end

      require "fresh_connection"

      unless defined?(FreshConnection::Railtie)
        abort "FreshConnection::Railtie was not auto-required when Rails::Railtie is defined"
      end

      inits = FreshConnection::Railtie.initializers.each_with_object({}) do |entry, memo|
        memo[entry[:name]] = entry
      end

      unless inits.key?("fresh_connection.deprecator") &&
             inits["fresh_connection.deprecator"][:opts][:before] == :load_environment_config
        abort "Missing or misconfigured fresh_connection.deprecator initializer: #{inits.inspect}"
      end

      unless inits.key?("fresh_connection.deprecation_behavior") &&
             inits["fresh_connection.deprecation_behavior"][:opts][:after] == "active_support.deprecation_behavior"
        abort "Missing or misconfigured fresh_connection.deprecation_behavior initializer: #{inits.inspect}"
      end

      unless inits.key?("fresh_connection.configure_rails_initialization")
        abort "Missing fresh_connection.configure_rails_initialization initializer"
      end

      # 1. Rails 7.1+ style app.deprecators registration
      modern_app = Struct.new(:deprecators).new({})
      inits["fresh_connection.deprecator"][:block].call(modern_app)
      unless modern_app.deprecators[:fresh_connection].equal?(FreshConnection.deprecator)
        abort "Expected app.deprecators[:fresh_connection] to be FreshConnection.deprecator"
      end

      # 2. Legacy (Rails <= 7.0) app deprecation_behavior sync
      if ActiveSupport::Deprecation.respond_to?(:behavior)
        legacy_app = Object.new
        custom_behavior = ->(_msg, *_args) {}
        ActiveSupport::Deprecation.behavior = custom_behavior
        inits["fresh_connection.deprecation_behavior"][:block].call(legacy_app)
        unless FreshConnection.deprecator.behavior == ActiveSupport::Deprecation.behavior
          abort "Expected FreshConnection.deprecator.behavior to sync from ActiveSupport::Deprecation.behavior"
        end
      end

      # 3. ExecutorHook installation via ActiveSupport.on_load(:active_record)
      inits["fresh_connection.configure_rails_initialization"][:block].call(modern_app)
      require "active_record"
      ActiveRecord::Base

      completed = 0
      FreshConnection::ExecutorHook.define_singleton_method(:complete) do |*_args|
        completed += 1
      end

      ActiveSupport::Executor.wrap do
        # simulate a Rails request/job
      end

      unless completed == 1
        abort "Expected ActiveSupport::Executor.wrap to invoke ExecutorHook.complete once, got #{completed}"
      end

      puts "RAILTIE_OK"
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-I#{lib_dir}", "-e", script)
    assert status.success?, "Railtie subprocess failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
    assert_includes stdout, "RAILTIE_OK"
  end
end
