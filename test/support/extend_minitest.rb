module Minitest
  class Test
    class << self
      def test(name, &block)
        test_name = "test_#{name.gsub(/\s+/,'_')}"
        raise "test '#{name}' is already defined" if method_defined?(test_name)
        define_method(test_name, &block)
      end
    end
  end
end
