module ExtendMinitest
  def test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}"
    raise "test '#{name}' is already defined" if method_defined?(test_name)
    define_method(test_name, &block)
  end

  def setup
    ActiveRecord::Base.configurations.clear     # reset all configurations before each test
  end
end

unless defined?(Minitest::Test)
  Minitest::Test = Minitest::Unit::TestCase
end

Minitest::Test.extend ExtendMinitest
