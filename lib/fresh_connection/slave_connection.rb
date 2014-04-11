require 'active_support/deprecation'

module FreshConnection
  #
  # This class has been deprecated.
  # It will delete at next version.
  #
  class SlaveConnection
    class << self
      def ignore_models=(models)
        deprecation("ignore_models=", "ActiveRecord::Base.master_db_only!")
        models.each do |model|
          if model.is_a?(String)
            model.constantize.master_db_only!
          elsif model.ancestors.include?(ActiveRecord::Base)
            model.master_db_only!
          end
        end
      end

      def ignore_configure_connection=(flag)
        deprecation("ignore_configure_connection=", "FreshConnection.ignore_configure_connection=")
        FreshConnection.ignore_configure_connection = flag
      end

      def connection_manager=(manager)
        deprecation("connection_manager=", "FreshConnection.connection_manager=")
        FreshConnection.connection_manager = manager
      end

      def slave_connection
        raise_deprecation_exception("slave_connection", "ArtiveRecord::Base.slave_connection")
      end

      private

      def deprecation(method_name, instead_method)
        ActiveSupport::Deprecation.warn(deprecation_message(method_name, instead_method))
      end

      def raise_deprecation_exception(method_name, instead_method)
        if defined?(ActiveSupport::DeprecationException)
          raise ActiveSupport::DeprecationException, deprecation_message(method_name, instead_method)
        else
          raise "ActiveSupport::DeprecationException: #{deprecation_message(method_name, instead_method)}"
        end
      end

      def deprecation_message(method_name, instead_method)
        "FreshConnection::SlaveConnection.#{method_name} has been deprecated. Use #{instead_method} instead"
      end
    end
  end
end
