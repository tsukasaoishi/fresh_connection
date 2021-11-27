require "minitest/autorun"

require "minitest/reporters"
Minitest::Reporters.use!

class Object
  def exception_or_super name, callable
    new_name = "__minitest_stub__#{name}"

    metaclass = class << self; self; end

    if respond_to? name and not methods.map(&:to_s).include? name.to_s then
      metaclass.send :define_method, name do |*args, &blk|
        super(*args, &blk)
      end
    end

    metaclass.send :alias_method, new_name, name

    metaclass.send :define_method, name do |*args, &blk|
      callable.call
      send new_name, *args, &blk
    end

    yield self
  ensure
    metaclass.send :undef_method, name
    metaclass.send :alias_method, name, new_name
    metaclass.send :undef_method, new_name
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fresh_connection'

require_relative "config/prepare"
