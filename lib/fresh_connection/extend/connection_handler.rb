module FreshConnection
  module Extend
    module ConnectionHandler
      def retrieve_connection(klass)
        c = super
        c.model_class = klass
        c
      end
    end
  end
end

