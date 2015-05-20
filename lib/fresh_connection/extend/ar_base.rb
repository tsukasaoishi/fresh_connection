require 'active_support/core_ext/class/attribute'
require 'fresh_connection/slave_connection_handler'
require 'fresh_connection/access_control'

module FreshConnection
  module Extend
    module ArBase
      def self.extended(base)
        base.class_attribute :slave_connection_handler, :instance_writer => false
        base.slave_connection_handler = FreshConnection::SlaveConnectionHandler.new
      end

      case ActiveRecord::VERSION::MAJOR
      when 4
        delegate :read_master, to: :all
      when 3
        delegate :read_master, to: :scoped
      end

      def manage_access(slave_access, &block)
        if master_db_only?
          FreshConnection::AccessControl.force_master_access(&block)
        else
          FreshConnection::AccessControl.access(slave_access, &block)
        end
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
        @_fresh_connection_master_only ||
          (self != ActiveRecord::Base && superclass.master_db_only?)
      end

      def slave_connection_put_aside!
        slave_connection_handler.put_aside!
      end

      def recovery(failure_connection, exception)
        slave_connection_handler.recovery(self, failure_connection, exception)
      end

      def slave_group
        slave_connection_handler.slave_group(self)
      end
    end
  end
end
