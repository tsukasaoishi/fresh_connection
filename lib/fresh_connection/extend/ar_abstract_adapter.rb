module FreshConnection
  module Extend
    module ArAbstractAdapter
      def self.prepended(base)
        base.send :attr_accessor, :replica_group
        base.send :attr_accessor, :connection_pool
      end

      def initialize(connection, logger = nil, config = {})
        super
        @connection_pool = nil
      end

      def log(*args)
        args[1] = "[#{@replica_group}] #{args[1]}" if defined?(@replica_group)
        super
      end

      # This is normally called only on master connections, so we need
      # to clear the replica connection caches, too.  But, don't recurse.
      def clear_query_cache
        if FreshConnection::ReplicaConnectionHandler.replica_query_cache_sync

          # This call is interesting.  Here, in the FreshConnection
          # extension to the AR AbstractAdapter, we are either on a :master
          # connection or a :replica connection.  Unfortunately, there is no direct
          # linkage between them.  So, from a :master connection, we don't know
          # which :replica connection pool to use, or even which :replica connection
          # manager to use, because those are associated with AR objects, not
          # AR adapters.

          # So, we need to "cross over" from the master connection side to the
          # replica connection side, via a top-level AR::Base call, but we need
          # to avoid accidental recursions, too.  The "replica_group" test
          # should be non-nil for replica connections.

          if replica_group.nil? || replica_group == :master
            ActiveRecord::Base.clear_replica_query_caches!
          end
        end
        super
      end
    end
  end
end
