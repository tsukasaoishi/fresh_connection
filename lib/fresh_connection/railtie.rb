require 'fresh_connection/executor_hook'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      ActiveSupport.on_load(:active_record) do
        FreshConnection::ExecutorHook.install_executor_hooks
      end
    end
  end
end
