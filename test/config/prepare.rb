require 'yaml'
require 'erb'
require 'active_record'
require 'fresh_connection'

REPLICA_NAMES = %w( replica1 replica2 fake_replica )

case ENV['DB_ADAPTER']
when 'mysql2'
  puts "[mysql2]"
  system("mysql -uroot < test/config/mysql_schema.sql")
when 'postgresql'
  puts "[postgresql]"
  system("psql -q -f test/config/psql_test_master.sql   fresh_connection_test_master  ")
  system("psql -q -f test/config/psql_test_replica1.sql fresh_connection_test_replica1")
  system("psql -q -f test/config/psql_test_replica2.sql fresh_connection_test_replica2")
end

module ActiveRecord
  class Base
    # don't read the database config file if database envars are defined
    unless ENV['DATABASE_URL'].present? && (ENV['DATABASE_REPLICA_URL'].present? || ENV['DATABASE_REPLICA1_URL'])
      configs = YAML.load(ERB.new(File.read(File.join(__dir__, "database_#{ENV['DB_ADAPTER']}.yml"))).result)
    else
      db_adapter = ENV['DB_ADAPTER']
      db_user    = ENV['DB_USER']
      configs = { "test" => { "adapter" => db_adapter, "username" => db_user, "url" => ENV['DATABASE_URL'] } }
      REPLICA_NAMES.each do |name|
        envar = "DATABASE_#{name.upcase}_URL"
        if (url = ENV[envar])
          configs.merge!( name => { "adapter" => db_adapter, "username" => db_user, "url" => url})
        end
      end
    end
    self.configurations = configs
    ENV['RAILS_ENV'] = 'test'     # set the default connection name
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
