require 'yaml'
module ActiveRecord
  class Base
    self.configurations = YAML.load_file(File.join(File.dirname(__FILE__), "database.yml"))
    establish_fresh_connection :slave1
  end
end

class User < ActiveRecord::Base
end

class Address < ActiveRecord::Base
end

class Tel < ActiveRecord::Base
end

p User.first
