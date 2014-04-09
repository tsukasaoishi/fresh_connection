module FreshConnection
  module Extend
    module ArBase
      def manage_access(slave_access, &block)
        if master_db_only?
          FreshConnection::AccessControl.force_master_access(&block)
        else
          FreshConnection::AccessControl.access(slave_access, &block)
        end
      end

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
