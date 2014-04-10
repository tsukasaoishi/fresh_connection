RAILS_ENV="test"
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fresh_connection'

class Dummy
  def method_missing(name, *args)
    return if name == "swap"
    self.class.new.__send__(name, *args)
  end
end
FreshConnection::Railtie.run_initializers(Dummy.new)

Dir[File.join(File.dirname(__FILE__), "/support/**/*.rb")].each {|f| require f}
