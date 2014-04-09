module FreshConnection
  module Extend
    module ArBase
      def master_only!
        @_fresh_connection_master_only = true
      end

      def master_only?
        !!@_fresh_connection_master_only
      end
    end
  end
end
