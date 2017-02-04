require 'fresh_connection/access_control'
require 'fresh_connection/slave_connection_handler'

module FreshConnection
  module Extend
    module ArBase
      def connection
        if FreshConnection::AccessControl.slave_access?
          if logger && logger.debug?
            slave_connection.tap{|c| c.slave_group = slave_group }
          else
            slave_connection
          end
        else
          super
        end
      end

      def read_master
        all.read_master
      end

      def with_master(&block)
        all.manage_access(false, &block)
      end

      def establish_fresh_connection(slave_group = nil)
        slave_connection_handler.establish_connection(name, slave_group)
      end

      def slave_connection
        slave_connection_handler.connection(self)
      end

      def clear_all_slave_connections!
        slave_connection_handler.clear_all_connections!
      end

      def master_db_only!
        @_fresh_connection_master_only = true
      end

      def master_db_only?
        @_fresh_connection_master_only ||=
          (self != ActiveRecord::Base && superclass.master_db_only?)
      end

      def slave_connection_put_aside!
        slave_connection_handler.put_aside!
      end

      def slave_connection_recovery?
        slave_connection_handler.recovery?(self)
      end

      def slave_group
        slave_connection_handler.slave_group(self)
      end

      private

      def slave_connection_handler
        @@slave_connection_handler ||= FreshConnection::SlaveConnectionHandler.new
      end
    end
  end
end
