require 'rails'

module FreshConnection
  class Railtie < Rails::Railtie
    initializer "fresh_connection.configure_rails_initialization" do |app|
      Initializer.swap_rack(app)

      ActiveSupport.on_load(:active_record) do
        Initializer.extend_active_record
      end
    end
  end
end
