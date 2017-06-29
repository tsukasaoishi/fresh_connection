require "minitest/autorun"

require "minitest/reporters"
Minitest::Reporters.use!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fresh_connection'

require_relative "config/prepare"
