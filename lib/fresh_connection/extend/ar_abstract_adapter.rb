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
    end
  end
end
