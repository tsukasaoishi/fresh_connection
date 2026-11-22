# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArRelation
      if RUBY_VERSION >= "3.0"
        def calculate(*, **, &block)
          manage_access { super }
        end

        def exists?(*, **, &block)
          manage_access { super }
        end

        def pluck(*, **, &block)
          manage_access { super }
        end

        if ActiveRecord::Relation.method_defined?(:load_async)
          def load_async(*, **, &block)
            if FreshConnection::RailsReplica.use_rails_replica?(klass)
              # Return nil from manage_access so Rails' connected_to does not force synchronous `.load` on the returned Relation.
              result = nil
              manage_access do
                result = super
                nil
              end
              result
            else
              super
            end
          end
        end
      else
        def calculate(*args, &block)
          manage_access { super(*args, &block) }
        end

        def exists?(*args, &block)
          manage_access { super(*args, &block) }
        end

        def pluck(*args, &block)
          manage_access { super(*args, &block) }
        end

        if ActiveRecord::Relation.method_defined?(:load_async)
          def load_async(*args, &block)
            if FreshConnection::RailsReplica.use_rails_replica?(klass)
              result = nil
              manage_access do
                result = super(*args, &block)
                nil
              end
              result
            else
              super(*args, &block)
            end
          end
        end

        if respond_to?(:ruby2_keywords, true)
          ruby2_keywords :calculate
          ruby2_keywords :exists?
          ruby2_keywords :pluck
          ruby2_keywords :load_async if method_defined?(:load_async)
        end
      end

      def read_master
        spawn.read_master!
      end

      def read_master!
        self.read_master_value = true
        self
      end

      def read_master_value
        @values[:read_master]
      end

      def read_master_value=(value)
        if respond_to?(:assert_mutability!, true)
          assert_mutability!
        elsif @loaded
          raise(
            defined?(ActiveRecord::UnmodifiableRelation) ? ActiveRecord::UnmodifiableRelation : ActiveRecord::ImmutableRelation
          )
        end
        @values[:read_master] = value
      end

      def manage_access(replica_access: enable_replica_access, &block)
        FreshConnection::AccessControl.manage_access(
          model: klass,
          replica_access: replica_access,
          force_master: force_master_access?,
          &block
        )
      end

      private

      def exec_queries(&block)
        manage_access { super(&block) }
      end

      def force_master_access?
        return true if read_master_value
        return true if respond_to?(:lock_value) && lock_value
        return true if FreshConnection::RailsReplica.explicitly_connected_to_writing?(klass)

        false
      end

      def enable_replica_access
        return false if force_master_access?
        return false if FreshConnection::AccessControl.in_transaction?(klass)

        true
      end
    end
  end
end
