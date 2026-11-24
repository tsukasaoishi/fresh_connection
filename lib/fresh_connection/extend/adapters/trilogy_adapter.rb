# frozen_string_literal: true

require 'fresh_connection/extend/adapters/base_adapter'

module FreshConnection
  module Extend
    module TrilogyAdapter
      private

      def __change_connection(&block)
        __swap_raw_connection(swap_statements: true, &block)
      end
    end
  end
end
