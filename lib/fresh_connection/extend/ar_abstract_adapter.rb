module FreshConnection
  module Extend
    module ArAbstractAdapter
      def self.prepended(base)
        base.send :attr_writer, :replica_group
      end

      def log(*args)
        args[1] = "[#{@replica_group}] #{args[1]}" if defined?(@replica_group)
        super
      end

      # This is normally called only on master connections, so we need
      # to clear the replica connection caches, too.  But, don't recurse.
      #def clear_query_cache
      #  replica_connection.clear_query_cache unless replica_group
      #end
    end
  end
end
