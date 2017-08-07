require 'active_support/deprecation'

module FreshConnection
  class Deprecation
    class << self
      def warn(list = {})
        list.each do |old_method, new_method|
          ActiveSupport::Deprecation.warn(
            "'#{old_method}' is deprecated and will removed from version 2.5.0. use '#{new_method}' instead."
          )
        end
      end
    end
  end
end
