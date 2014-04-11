module FreshConnection
  module Extend
    module ConnectionHandler
      def self.included(base)
        base.alias_method_chain :retrieve_connection, :fresh_connection
      end

      def retrieve_connection_with_fresh_connection(klass)
        c = retrieve_connection_without_fresh_connection(klass)
        c.model_class = klass
        c
      end
    end
  end
end

