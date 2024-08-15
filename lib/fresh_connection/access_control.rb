# frozen_string_literal: true

module FreshConnection
  class AccessControl
    class << self
      RETRY_LIMIT = 3
      private_constant :RETRY_LIMIT

      def manage_access(model:, replica_access:, &block)
        return force_master_access(&block) if model.master_db_only?

        retry_count = 0
        begin
          access(replica_access, &block)
        rescue *catch_exceptions
          if recovery?(model.replica_spec_name)
            retry_count += 1
            retry if retry_count < RETRY_LIMIT
          end

          raise
        end
      end

      def replica_access?
        access_db == :replica
      end

      private

      def force_master_access(&block)
        switch_to(:master, &block)
      end

      def access(replica_access, &block)
        return yield if access_db

        db = replica_access ? :replica : :master
        switch_to(db, &block)
      end

      def switch_to(new_db)
        old_db = access_db
        access_to(new_db)
        yield
      ensure
        access_to(old_db)
      end

      def access_db
        Thread.current[:fresh_connection_access_target]
      end

      def access_to(db)
        Thread.current[:fresh_connection_access_target] = db
      end

      def recovery?(spec_name)
        FreshConnection::ReplicaConnectionHandler.instance.recovery?(spec_name)
      end

      def catch_exceptions
        return @catch_exceptions if defined?(@catch_exceptions)
        @catch_exceptions = [
          ActiveRecord::StatementInvalid,
          ActiveRecord::ConnectionNotEstablished
        ]

        @catch_exceptions << ::Mysql2::Error if defined?(::Mysql2)

        if defined?(::PG)
          @catch_exceptions << ::PG::Error
          @catch_exceptions << ::PGError if defined?(::PGError)
        end

        @catch_exceptions
      end
    end
  end
end
