require 'yaml'

%w|master slave1 slave2|.each do |db|
  system("mysql -uroot fresh_connection_test_#{db} < spec/db_schema.sql")
end

module ActiveRecord
  class Base
    self.configurations = YAML.load_file(File.join(File.dirname(__FILE__), "database.yml"))
    establish_connection
    establish_fresh_connection :slave1
  end
end

class User < ActiveRecord::Base
  has_one :address
  has_many :tels
end

class Address < ActiveRecord::Base
  belongs_to :user
end

class Tel < ActiveRecord::Base
  belongs_to :user
end
