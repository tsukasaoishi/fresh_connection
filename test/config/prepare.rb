require 'yaml'
require 'erb'
require 'active_record'
require 'active_record/base'
require 'fresh_connection'

if ActiveRecord::VERSION::MAJOR == 6 && ActiveRecord::VERSION::MINOR == 1
  db_config = ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(ENV["DATABASE_URL"]).to_hash
else
  db_config = ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(ENV["DATABASE_URL"]).to_hash
end

REPLICA_NAMES = %w( replica1 replica2 fake_replica )

case db_config['adapter']
when 'mysql2'
  work = []
  work << "-u#{db_config["username"]}" if db_config["username"]
  work << "-p#{db_config["password"]}" if db_config["password"]
  work << "-h#{db_config["host"]}" if db_config["host"]
  work << "-P#{db_config["port"]}" if db_config["port"]
  command = work.join(" ")

  system("mysql #{command} < test/config/mysql_schema.sql")
when 'postgresql'
  puts "[postgresql]"
  work = []
  work << "-U#{db_config["username"]}" if db_config["username"]
  work << "-W#{db_config["password"]}" if db_config["password"]
  work << "-h#{db_config["host"]}" if db_config["host"]
  work << "-p#{db_config["port"]}" if db_config["port"]
  command = work.join(" ")


  {
    fresh_connection_test_master: "psql_test_master.sql",
    fresh_connection_test_replica1: "psql_test_replica1.sql",
    fresh_connection_test_replica2: "psql_test_replica2.sql"
  }.each do |db, file|
    if system("psql -l #{command} | grep #{db}")
      puts "Dropping database #{db}"
      system("dropdb #{command} #{db}")
    end

    puts "Creating database #{db}"
    system("createdb #{command} #{db}")
    system("psql -q #{command} -f test/config/#{file} #{db}")
  end
end

module ActiveRecord
  class Base
    establish_connection
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

if db_config['adapter'] == "postgresql"
  ActiveRecord::Base.connection.execute("select setval('addresses_id_seq',(select max(id) from addresses))")
end

require "support/extend_minitest"
require "support/active_record_logger"
