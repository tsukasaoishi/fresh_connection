require 'yaml'

system("mysql -uroot < spec/db_schema.sql")

module ActiveRecord
  class Base
    self.configurations = YAML.load_file(File.join(File.dirname(__FILE__), "database.yml"))
    establish_connection(configurations["test"])
    establish_fresh_connection :slave1
  end
end

class Parent < ActiveRecord::Base
  self.abstract_class = true
end

class Slave2 < ActiveRecord::Base
  self.abstract_class = true
  establish_fresh_connection :slave2
end

class User < ActiveRecord::Base
  has_one :address
  has_many :tels
end

class Address < ActiveRecord::Base
  belongs_to :user
end

class Tel < Slave2
  belongs_to :user
end
