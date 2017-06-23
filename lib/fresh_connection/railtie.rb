require 'fresh_connection/executor_hook'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      FreshConnection::ExecutorHook.install_executor_hooks
    end
  end
end
