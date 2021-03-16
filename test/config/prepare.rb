require 'yaml'
require 'erb'
require 'active_record'
require 'fresh_connection'

class DbConfig
  def self.config
    return @config if defined?(@config)
    c = YAML.load_file(File.join(__dir__, config_file))[ENV["FC_TEST_ADAPTER"]]
    @config = { test: c }
  end

  def self.config_file
    %w(database.local.yml database.yml).detect do |f|
      File.exist?(File.join(__dir__, f))
    end
  end
end

db_config = DbConfig.config

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
    self.configurations = DbConfig.config
    establish_connection
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :primary, reading: :replica1 }
end

class Parent < ApplicationRecord
  self.abstract_class = true
end

class Replica2 < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :primary, reading: :replica2 }
end

class User < ApplicationRecord
  has_one :address
  has_many :tels
end

class Address < ApplicationRecord
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
