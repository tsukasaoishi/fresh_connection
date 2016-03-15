module FreshConnection
  module Extend
    module ArRelation
      def manage_access(slave_access = enable_slave_access, &block)
        if @klass.master_db_only?
          FreshConnection::AccessControl.force_master_access(&block)
        else
          FreshConnection::AccessControl.access(slave_access, &block)
        end
      end

      def calculate(*args)
        manage_access { super }
      end

      def exists?(*args)
        manage_access { super }
      end

      def pluck(*args)
        manage_access { super }
      end

      def read_master
        spawn.read_master!
      end

      def read_master!
        @read_from_master = true
        self
      end

      def enable_slave_access
        connection.open_transactions == 0 && @read_from_master.nil?
      end

      private

      def exec_queries
        manage_access { super }
      end
    end
  end
end

if ActiveRecord::VERSION::MAJOR == 3
  require "fresh_connection/extend/ar_relation/for_rails3"
  FreshConnection::Extend::ArRelation.send :prepend, FreshConnection::Extend::ArRelation::ForRails3
end
