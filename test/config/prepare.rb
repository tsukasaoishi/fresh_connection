require 'yaml'
require 'erb'
require 'active_record'
require 'fresh_connection'

REPLICA_NAMES = %w( replica1 replica2 fake_replica )

case ENV['DB_ADAPTER']
when 'mysql2'
  puts "[mysql2]"
  m_h = " -h #{ENV['TEST_MYSQL_HOST']} " if ENV['TEST_MYSQL_HOST']
  system("mysql -uroot #{m_h} < test/config/mysql_schema.sql")
when 'postgresql'
  puts "[postgresql]"
  p_h = " -h #{ENV['TEST_PSGR_HOST']} " if ENV['TEST_PSGR_HOST']

  {
    fresh_connection_test_master: "psql_test_master.sql",
    fresh_connection_test_replica1: "psql_test_replica1.sql",
    fresh_connection_test_replica2: "psql_test_replica2.sql"
  }.each do |db, file|
    if system("psql -l #{p_h} | grep #{db}")
      puts "Dropping database #{db}"
      system("dropdb #{p_h} #{db}")
    end

    puts "Creating database #{db}"
    system("createdb #{p_h} #{db}")
    system("psql -q #{p_h} -f test/config/#{file} #{db}")
  end
end

module ActiveRecord
  class Base
    configs = YAML.load(ERB.new(File.read(File.join(__dir__, "database_#{ENV['DB_ADAPTER']}.yml"))).result)
    self.configurations = configs
    establish_connection(configurations["test"])
    establish_fresh_connection :replica1
  end
end

class Parent < ActiveRecord::Base
  self.abstract_class = true
end

class Replica2 < ActiveRecord::Base
  self.abstract_class = true
  establish_fresh_connection :replica2
end

class User < ActiveRecord::Base
  has_one :address
  has_many :tels
end

class Address < ActiveRecord::Base
  belongs_to :user
end

class Tel < Replica2
  belongs_to :user
end

if ENV['DB_ADAPTER'] == "postgresql"
  ActiveRecord::Base.connection.execute("select setval('addresses_id_seq',(select max(id) from addresses))")
end

require "support/extend_minitest"
require "support/active_record_logger"
