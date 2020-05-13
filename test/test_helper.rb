$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require 'fresh_connection'

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "config/prepare"
