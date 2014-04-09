module FreshConnection
  module Extend
    module ArBase
      def master_db_only!
        @_fresh_connection_master_only = true
      end

      def master_db_only?
        @_fresh_connection_master_only ||
          (self != ActiveRecord::Base && superclass.master_db_only?)
      end
    end
  end
end
