# frozen_string_literal: true
require 'fresh_connection/access_control'
require 'fresh_connection/replica_connection_handler'

module FreshConnection
  module Extend
    module ArBase
      def read_master
        all.read_master
      end

      def with_master(&block)
        FreshConnection::AccessControl.manage_access(
          model: self,
          replica_access: false,
          force_master: true,
          &block
        )
      end

      if ActiveRecord::VERSION::MAJOR < 7 || (ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR < 2)
        def connection
          if FreshConnection::AccessControl.managed? &&
             FreshConnection::RailsReplica.in_reading_role?(self) &&
             !FreshConnection::RailsReplica.use_rails_replica?(self)
            return FreshConnection::RailsReplica.with_writing(self) { super.tap { |c| c.model_class = self } }
          end

          super.tap { |c| c.model_class = self }
        end
      end

      def replica_connection
        if FreshConnection::RailsReplica.use_rails_replica?(self)
          pool = FreshConnection::RailsReplica.reading_pool_for(self)
          pool.respond_to?(:lease_connection) ? pool.lease_connection : pool.connection
        else
          __replica_handler.connection(replica_spec_name)
        end
      end

      def clear_all_replica_connections!
        __replica_handler.clear_all_connections!
        FreshConnection::RailsReplica.clear_all_connections!
      end

      def establish_fresh_connection(spec_name = nil)
        FreshConnection.deprecator.warn(
          "establish_fresh_connection is deprecated and will be removed in FreshConnection 3.2.0. " \
          "Please configure read replicas using Rails' native `connects_to` (database: { writing: ..., reading: ... }) instead."
        )

        spec_name = spec_name.to_s
        spec_name = "replica" if spec_name.empty?
        @_replica_spec_name = spec_name
        @_explicit_fresh_connection = true

        __replica_handler.refresh_connection(replica_spec_name)
      end

      def explicit_fresh_connection?
        conn_class = FreshConnection::RailsReplica.supported? ? FreshConnection::RailsReplica.connection_class_for(self) : ActiveRecord::Base
        klass = self

        loop do
          if klass.instance_variable_defined?(:@_explicit_fresh_connection) &&
             klass.instance_variable_get(:@_explicit_fresh_connection)
            return true
          end
          break if klass == conn_class || klass == ActiveRecord::Base

          klass = klass.superclass
          break unless klass
        end

        false
      end

      def master_db_only!
        @_fresh_connection_master_only = true
      end

      def master_db_only?
        @_fresh_connection_master_only ||=
          (self != ActiveRecord::Base && superclass.master_db_only?)
      end

      def replica_spec_name
        if FreshConnection::RailsReplica.use_rails_replica?(self)
          pool = FreshConnection::RailsReplica.reading_pool_for(self)
          return pool.db_config.name.to_s if pool && pool.respond_to?(:db_config)
        end

        @_replica_spec_name ||= __search_replica_spec_name
      end

      private

      def __search_replica_spec_name
        if self == ActiveRecord::Base
          "replica"
        else
          superclass.replica_spec_name
        end
      end

      def __replica_handler
        FreshConnection::ReplicaConnectionHandler.instance
      end
    end

    module ArQueryCache
      def cache(&block)
        if FreshConnection::RailsReplica.supported? && !FreshConnection.custom_connection_manager?
          super { FreshConnection::RailsReplica.with_reading_pools_query_cache(enable: true, &block) }
        else
          super
        end
      end

      if RUBY_VERSION >= "3.0"
        def uncached(*args, **kwargs, &block)
          if FreshConnection::RailsReplica.supported? && !FreshConnection.custom_connection_manager?
            dirties = kwargs.fetch(:dirties, true)
            super(*args, **kwargs) do
              FreshConnection::RailsReplica.with_reading_pools_query_cache(enable: false, dirties: dirties, &block)
            end
          else
            super(*args, **kwargs, &block)
          end
        end
      else
        def uncached(*args, &block)
          if FreshConnection::RailsReplica.supported? && !FreshConnection.custom_connection_manager?
            dirties = args.last.is_a?(Hash) && args.last.key?(:dirties) ? args.last[:dirties] : true
            super(*args) do
              FreshConnection::RailsReplica.with_reading_pools_query_cache(enable: false, dirties: dirties, &block)
            end
          else
            super(*args, &block)
          end
        end
        ruby2_keywords :uncached if respond_to?(:ruby2_keywords, true)
      end
    end

    module ArConnectedTo
      if RUBY_VERSION >= "3.0"
        def connected_to(*args, **kwargs, &block)
          FreshConnection::RailsReplica.with_user_connected_to(self, kwargs[:role]) do
            super(*args, **kwargs, &block)
          end
        end
      else
        def connected_to(*args, &block)
          role = args.last.is_a?(Hash) ? args.last[:role] : nil
          FreshConnection::RailsReplica.with_user_connected_to(self, role) do
            super(*args, &block)
          end
        end
        ruby2_keywords :connected_to if respond_to?(:ruby2_keywords, true)
      end
    end

    module ArCachedFindBy
      private

      if RUBY_VERSION >= "3.0"
        def cached_find_by(*, **, &block)
          all.manage_access { super }
        end
      else
        def cached_find_by(*args, &block)
          all.manage_access { super(*args, &block) }
        end
        ruby2_keywords :cached_find_by if respond_to?(:ruby2_keywords, true)
      end
    end
  end
end
