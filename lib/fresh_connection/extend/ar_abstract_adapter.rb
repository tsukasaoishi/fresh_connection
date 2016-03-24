module FreshConnection
  module Extend
    module ArAbstractAdapter
      def self.prepended(base)
        base.send :attr_writer, :slave_group
      end

      def log(*args)
        args[1] = "[#{@slave_group}] #{args[1]}" if @slave_group
        super
      end
    end
  end
end
