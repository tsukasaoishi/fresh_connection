require 'fresh_connection/executor_hook'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      ActiveSupport.on_load(:active_record) do
        FreshConnection::ExecutorHook.install_executor_hooks
      end
    end

    initializer "fresh_connection.initialize_database", after: "active_record.initialize_database" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.establish_fresh_connection
      end
    end
  end
end
