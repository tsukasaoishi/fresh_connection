# frozen_string_literal: true

require 'logger'
require 'active_support/deprecation'

module FreshConnection
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("3.2.0", "FreshConnection")
  end
end
