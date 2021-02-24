# frozen_string_literal: true

module FreshConnection
  module Extend
    module OtherAdapterProxy
      private

      def __change_connection
        yield
      end
    end
  end
end
