# frozen_string_literal: true
require 'fresh_connection/executor_hook'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.deprecator", before: :load_environment_config do |app|
      if app.respond_to?(:deprecators)
        app.deprecators[:fresh_connection] = FreshConnection.deprecator
      end
    end

    initializer "fresh_connection.deprecation_behavior", after: "active_support.deprecation_behavior" do |app|
      if !app.respond_to?(:deprecators) && ActiveSupport::Deprecation.respond_to?(:behavior)
        FreshConnection.deprecator.behavior = ActiveSupport::Deprecation.behavior
      end
    end

    initializer "fresh_connection.configure_rails_initialization" do |_app|
      ActiveSupport.on_load(:active_record) do
        FreshConnection::ExecutorHook.install_executor_hooks
      end
    end
  end
end
