require 'minitest/autorun'
require "minitest/reporters"
Minitest::Reporters.use!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fresh_connection'

require File.join(File.dirname(__FILE__), "prepare.rb")

Dir[File.join(File.dirname(__FILE__), "/support/**/*.rb")].each {|f| require f}

module Minitest
  class Test
    class << self
      def group(name)
        @group_name = name
        yield
      ensure
        @group_name = nil
      end

      def test(name, &block)
        name = "#{@group_name} #{name}" if @group_name
        test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
        raise "#{test_name} is already defined in #{self}" if method_defined?(test_name)
        define_method(test_name, &block)
      end
    end
  end
end
