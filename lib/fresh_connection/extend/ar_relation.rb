# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArRelation
      def calculate(*)
        manage_access { super }
      end

      def exists?(*)
        manage_access { super }
      end

      def pluck(*)
        manage_access { super }
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
        raise ImmutableRelation if @loaded
        @values[:read_master] = value
      end

      def manage_access(replica_access: enable_replica_access, &block)
        FreshConnection::AccessControl.manage_access(
          model: @klass,
          replica_access: replica_access,
          &block
        )
      end

      private

      def exec_queries
        manage_access { super }
      end

      def enable_replica_access
        connection.open_transactions.zero? && !read_master_value
      end
    end
  end
end
