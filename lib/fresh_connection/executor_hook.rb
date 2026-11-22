# frozen_string_literal: true

module FreshConnection
  class ExecutorHook
    class << self
      def run
      end

      def complete(*_args)
        return unless FreshConnection.put_aside

        ReplicaConnectionHandler.instance.put_aside!
        RailsReplica.put_aside!
      end

      def install_executor_hooks
        ActiveSupport::Executor.register_hook(self)
      end
    end
  end
end
