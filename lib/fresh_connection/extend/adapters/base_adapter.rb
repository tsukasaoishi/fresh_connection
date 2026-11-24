# frozen_string_literal: true

module FreshConnection
  module Extend
    module BaseAdapter
      def self.prepended(base)
        base.send :attr_writer, :model_class
      end

      if RUBY_VERSION >= "3.0"
        def log(*args, **kwargs, &block)
          if (spec_name = __replica_spec_name)
            args[1] = "[#{spec_name}] #{args[1] || 'SQL'}"
          end
          super(*args, **kwargs, &block)
        end

        def select_all(*args, **kwargs, &block)
          __change_connection do
            if kwargs.key?(:allow_retry) && __legacy_replica_active?
              super(*args, **kwargs.merge(allow_retry: false), &block)
            else
              super(*args, **kwargs, &block)
            end
          end
        end

        def select_value(*, **, &block)
          __change_connection { super }
        end
      else
        def log(*args, &block)
          if (spec_name = __replica_spec_name)
            if args.length >= 2 && !args[1].is_a?(Hash)
              args[1] = "[#{spec_name}] #{args[1] || 'SQL'}"
            elsif args.length == 1
              args[1] = "[#{spec_name}] SQL"
            elsif args.length >= 2 && args[1].is_a?(Hash)
              args.insert(1, "[#{spec_name}] SQL")
            end
          end
          super(*args, &block)
        end

        def select_all(*args, &block)
          __change_connection { super(*args, &block) }
        end

        def select_value(*args, &block)
          __change_connection { super(*args, &block) }
        end

        if respond_to?(:ruby2_keywords, true)
          ruby2_keywords :log
          ruby2_keywords :select_all
          ruby2_keywords :select_value
        end
      end

      private

      def __target_model
        FreshConnection::AccessControl.current_model || (defined?(@model_class) ? @model_class : nil)
      end

      def __legacy_replica_active?
        return false unless FreshConnection::AccessControl.replica_access?

        model = __target_model
        !model.nil? && FreshConnection::RailsReplica.legacy_replica_enabled?(model)
      end

      def __replica_spec_name
        return nil unless FreshConnection::AccessControl.replica_access?

        model = __target_model
        return nil unless model

        if FreshConnection::RailsReplica.supported? &&
           !FreshConnection.custom_connection_manager? &&
           !model.explicit_fresh_connection?
          pool = FreshConnection::RailsReplica.reading_pool_for(model)
          if pool
            return pool.respond_to?(:db_config) ? pool.db_config.name.to_s : "replica"
          end
        end

        return nil unless FreshConnection::RailsReplica.legacy_replica_enabled?(model)

        model.replica_spec_name
      end

      def __swap_raw_connection(swap_statements: false)
        return yield unless FreshConnection::AccessControl.replica_access?

        model = __target_model
        return yield unless model
        return yield unless FreshConnection::RailsReplica.legacy_replica_enabled?(model)

        conn_ivar = __raw_connection_ivar
        master_connection = instance_variable_get(conn_ivar)
        has_statements = swap_statements && instance_variable_defined?(:@statements)
        master_statements = instance_variable_get(:@statements) if has_statements
        replica_raw = nil

        begin
          replica_connection = model.replica_connection
          replica_raw = replica_connection.instance_variable_get(conn_ivar)
          if replica_raw.nil?
            replica_connection.connect! if replica_connection.respond_to?(:connect!)
            replica_raw = replica_connection.instance_variable_get(conn_ivar) || replica_connection.raw_connection
          end
          instance_variable_set(conn_ivar, replica_raw)
          if has_statements
            instance_variable_set(:@statements, replica_connection.instance_variable_get(:@statements))
          end
          yield
        ensure
          current_raw = instance_variable_get(conn_ivar)
          if current_raw && current_raw != replica_raw && current_raw != master_connection
            current_raw.close if current_raw.respond_to?(:close) rescue nil
          end
          instance_variable_set(conn_ivar, master_connection)
          instance_variable_set(:@statements, master_statements) if has_statements
        end
      end

      def __raw_connection_ivar
        if ActiveRecord::VERSION::MAJOR > 7 || (ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR >= 1)
          :@raw_connection
        else
          :@connection
        end
      end
    end
  end
end
