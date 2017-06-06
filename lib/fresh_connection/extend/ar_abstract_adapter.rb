require 'pry-byebug'

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
          ActiveRecord::Base.clear_all_query_caches! unless replica_group
        end
        super
      end

    end
  end
end
