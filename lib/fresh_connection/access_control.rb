# frozen_string_literal: true

module FreshConnection
  class AccessControl
    class << self
      def manage_access(model:, replica_access:, force_master: false, &block)
        if model.master_db_only? || force_master
          return with_current_model(model) do
            force_master_access(&block)
          end
        end

        unless FreshConnection::RailsReplica.use_rails_replica?(model) ||
               FreshConnection::RailsReplica.legacy_replica_enabled?(model)
          return with_current_model(model) do
            if FreshConnection::RailsReplica.in_reading_role?(model)
              FreshConnection::RailsReplica.with_writing(model, &block)
            else
              yield
            end
          end
        end

        outermost = !managed?
        will_use_replica = replica_access && access_db != :master
        retry_count = 0
        begin
          with_current_model(model) do
            access(replica_access, &block)
          end
        rescue *catch_exceptions => e
          raise if exhausted_exception?(e)

          if will_use_replica &&
             !non_retryable_exception?(e) &&
             recovery_enabled? &&
             (retry_count + 1 < FreshConnection.retry_limit) &&
             with_last_exception(e) { recovery?(recovery_target(model)) }
            state_set(:fresh_connection_exhausted_exception, nil)
            retry_count += 1
            retry
          end

          state_set(:fresh_connection_exhausted_exception, e)
          raise
        ensure
          state_set(:fresh_connection_exhausted_exception, nil) if outermost
        end
      end

      def replica_access?
        access_db == :replica
      end

      def managed?
        !access_db.nil?
      end

      def current_model
        state_get(:fresh_connection_current_model)
      end

      def last_exception
        state_get(:fresh_connection_last_exception)
      end

      def in_transaction?(model)
        FreshConnection::RailsReplica.in_transaction?(model)
      end

      private

      def force_master_access(&block)
        switch_to(:master, &block)
      end

      def access(replica_access, &block)
        if access_db
          return ensure_rails_role(access_db, &block)
        end

        db = replica_access ? :replica : :master
        switch_to(db, &block)
      end

      def switch_to(new_db, &block)
        old_db = access_db
        access_to(new_db)
        ensure_rails_role(new_db, &block)
      ensure
        access_to(old_db)
      end

      def ensure_rails_role(target_db, &block)
        model = current_model
        return yield unless model

        if target_db == :replica
          return yield unless FreshConnection::RailsReplica.use_rails_replica?(model)

          FreshConnection::RailsReplica.with_reading(model, &block)
        else
          return yield unless FreshConnection::RailsReplica.supported? &&
                              (FreshConnection::RailsReplica.use_rails_replica?(model) ||
                               FreshConnection::RailsReplica.in_reading_role?(model) ||
                               FreshConnection::RailsReplica.any_reading_or_preventing_writes?)

          FreshConnection::RailsReplica.with_writing(model, &block)
        end
      end

      def with_current_model(model)
        old_model = current_model
        state_set(:fresh_connection_current_model, model)
        yield
      ensure
        state_set(:fresh_connection_current_model, old_model)
      end

      def with_last_exception(exception)
        old_exception = last_exception
        state_set(:fresh_connection_last_exception, exception)
        yield
      ensure
        state_set(:fresh_connection_last_exception, old_exception)
      end

      def exhausted_exception?(exception)
        exhausted = state_get(:fresh_connection_exhausted_exception)
        !exhausted.nil? && exhausted.equal?(exception)
      end

      def access_db
        state_get(:fresh_connection_access_target)
      end

      def access_to(db)
        state_set(:fresh_connection_access_target, db)
      end

      def state_get(key)
        if defined?(ActiveSupport::IsolatedExecutionState)
          ActiveSupport::IsolatedExecutionState[key]
        else
          Thread.current[key]
        end
      end

      def state_set(key, value)
        if defined?(ActiveSupport::IsolatedExecutionState)
          ActiveSupport::IsolatedExecutionState[key] = value
        else
          Thread.current[key] = value
        end
      end

      def recovery_enabled?
        FreshConnection.recovery && FreshConnection.retry_limit > 0
      end

      def non_retryable_exception?(exception)
        defined?(ActiveRecord::ConnectionNotDefined) && exception.is_a?(ActiveRecord::ConnectionNotDefined)
      end

      def recovery_target(model)
        if FreshConnection::RailsReplica.use_rails_replica?(model)
          model
        else
          model.replica_spec_name
        end
      end

      def recovery?(target)
        if target.is_a?(Class) && defined?(ActiveRecord::Base) && target <= ActiveRecord::Base
          FreshConnection::RailsReplica.recovery?(target, exception: last_exception)
        else
          FreshConnection::ReplicaConnectionHandler.instance.recovery?(target)
        end
      end

      def catch_exceptions
        exceptions = [
          ActiveRecord::StatementInvalid,
          ActiveRecord::ConnectionNotEstablished
        ]

        exceptions << ::Mysql2::Error if defined?(::Mysql2::Error)
        exceptions << ::Trilogy::Error if defined?(::Trilogy::Error)

        if defined?(::PG)
          exceptions << ::PG::Error if defined?(::PG::Error)
          exceptions << ::PGError if defined?(::PGError)
        end

        exceptions
      end
    end
  end
end
