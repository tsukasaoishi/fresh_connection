require 'yaml'
require 'active_record'
require 'fresh_connection'

system("mysql -uroot < test/config/db_schema.sql")

module ActiveRecord
  class Base
    self.configurations = YAML.load_file(File.join(__dir__, "database.yml"))
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

require "support/extend_minitest"
require "support/active_record_logger"
