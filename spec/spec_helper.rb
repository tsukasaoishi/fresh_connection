ENV["RAILS_ENV"]="test"
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fresh_connection'

FreshConnection::Initializer.extend_active_record

Dir[File.join(File.dirname(__FILE__), "/support/**/*.rb")].each {|f| require f}