# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArRelationMerger
      private

      def merge_single_values
        relation.read_master_value = values[:read_master] unless relation.read_master_value
        super
      end
    end
  end
end
