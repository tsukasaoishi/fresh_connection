module FreshConnection
  class SlaveConnection
    COUNT = :fresh_connection_access_count
    TARGET = :fresh_connection_access_target
    RETRY_LIMIT = 10

    class << self
      attr_writer :ignore_models, :ignore_configure_connection

      delegate :slave_connection, :put_aside!, :recoverable?, :recovery, :to => :connection_manager

      def manage_access(model_klass, go_slave, &block)
        if ignore_model?(model_klass)
          force_master_access(&block)
        else
          target = go_slave ? :slave : :master
          begin
            access_in(target)
            block.call
          ensure
            access_out
          end
        end
      end

      def slave_access?
        Thread.current[TARGET] == :slave
      end

      def ignore_model?(model_klass)
        @cached_ignore_model ||= {}
        return @cached_ignore_model[model_klass] if @cached_ignore_model.has_key?(model_klass)

        @cached_ignore_model[model_klass] = check_ignore_model(model_klass)
      end

      def ignore_configure_connection?
        !!@ignore_configure_connection
      end

      def connection_manager=(manager)
        @connection_manager_class = manager
      end

      def retry_limit
        RETRY_LIMIT
      end

      private

      def force_master_access
        now_target = Thread.current[TARGET]
        Thread.current[TARGET] = :master
        yield
      ensure
        Thread.current[TARGET] = now_target
      end

      def access_in(target)
        Thread.current[COUNT] = (Thread.current[COUNT] || 0) + 1
        Thread.current[TARGET] ||= target
      end

      def access_out
        Thread.current[COUNT] -= 1
        if Thread.current[COUNT] == 0
          Thread.current[TARGET] = nil
          Thread.current[COUNT] = nil
        end
      end

      def connection_manager
        @connection_manager ||=
          (@connection_manager_class || FreshConnection::ConnectionManager).new
      end

      def check_ignore_model(model_klass)
        (@ignore_models || []).one? do |ignore_model|
          if ignore_model.is_a?(String)
            ignore_model == model_klass.name
          elsif ignore_model.ancestors.include?(ActiveRecord::Base)
            model_klass.ancestors.include?(ignore_model)
          else
            false
          end
        end
      end
    end
  end
end
