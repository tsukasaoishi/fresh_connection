$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] ||= "test"
require 'fresh_connection'

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "config/prepare"
