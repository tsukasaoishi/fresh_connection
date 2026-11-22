require 'yaml'
require 'erb'
require 'active_record'
require 'active_record/base'
require 'fresh_connection'

def resolve_database_url(url)
  hash = if ActiveRecord::VERSION::MAJOR >= 7 || (ActiveRecord::VERSION::MAJOR == 6 && ActiveRecord::VERSION::MINOR == 1)
           ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(url).to_hash
         else
           ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(url).to_hash
         end
  hash.transform_keys(&:to_s)
end

db_config = resolve_database_url(ENV["DATABASE_URL"])

REPLICA_NAMES = %w( replica1 replica2 fake_replica )

case db_config['adapter']
when 'mysql2', 'trilogy'
  work = []
  work << "-u#{db_config["username"]}" if db_config["username"]
  work << "-p#{db_config["password"]}" if db_config["password"]
  work << "-h#{db_config["host"]}" if db_config["host"]
  work << "-P#{db_config["port"]}" if db_config["port"]
  command = work.join(" ")

  system("mysql #{command} < test/config/mysql_schema.sql") ||
    raise("Failed to load test/config/mysql_schema.sql")
when 'postgresql'
  puts "[postgresql]"
  work = []
  work << "-U#{db_config["username"]}" if db_config["username"]
  work << "-h#{db_config["host"]}" if db_config["host"]
  work << "-p#{db_config["port"]}" if db_config["port"]
  command = work.join(" ")
  pg_env = db_config["password"] ? { "PGPASSWORD" => db_config["password"].to_s } : {}

  {
    fresh_connection_test_master: "psql_test_master.sql",
    fresh_connection_test_replica1: "psql_test_replica1.sql",
    fresh_connection_test_replica2: "psql_test_replica2.sql"
  }.each do |db, file|
    if system(pg_env, "psql -l #{command} | grep #{db}")
      puts "Dropping database #{db}"
      system(pg_env, "dropdb #{command} #{db}") || raise("Failed to dropdb #{db}")
    end

    puts "Creating database #{db}"
    system(pg_env, "createdb #{command} #{db}") || raise("Failed to createdb #{db}")
    system(pg_env, "psql -q #{command} -f test/config/#{file} #{db}") || raise("Failed to load #{file} into #{db}")
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

if FreshConnection::RailsReplica.supported?
  env_name = defined?(ActiveRecord::ConnectionHandling::DEFAULT_ENV) ? ActiveRecord::ConnectionHandling::DEFAULT_ENV.call : "default_env"

  native_configs = {
    "primary" => db_config
  }
  {
    "replica1" => ENV["DATABASE_REPLICA1_URL"],
    "replica2" => ENV["DATABASE_REPLICA2_URL"],
    "fake_replica" => ENV["DATABASE_FAKE_REPLICA_URL"]
  }.each do |name, url|
    next unless url

    native_configs[name] = resolve_database_url(url).merge("replica" => true)
  end

  ActiveRecord::Base.configurations = { env_name => native_configs }

  class NativeRecord < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :primary, reading: :replica1 }
  end

  class NativeReplica2Record < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :primary, reading: :replica2 }
  end

  class NativeFakeReplicaRecord < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :primary, reading: :fake_replica }
  end

  class NativeUnreplicatedRecord < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :primary }
  end

  class NativeUser < NativeRecord
    self.table_name = :users
    has_one :native_address, foreign_key: :user_id
    has_many :native_tels, foreign_key: :user_id
    has_many :native_master_only_addresses, foreign_key: :user_id
    has_many :native_read_master_addresses, -> { read_master }, class_name: "NativeAddress", foreign_key: :user_id
    has_many :native_unreplicated_addresses, class_name: "NativeUnreplicatedAddress", foreign_key: :user_id
  end

  class NativeAddress < NativeRecord
    self.table_name = :addresses
    belongs_to :native_user, foreign_key: :user_id
  end

  class NativeTel < NativeReplica2Record
    self.table_name = :tels
    belongs_to :native_user, foreign_key: :user_id
  end

  class NativeFakeAddress < NativeFakeReplicaRecord
    self.table_name = :addresses
  end

  class NativeMasterOnlyBase < NativeRecord
    self.abstract_class = true
    master_db_only!
  end

  class NativeMasterOnlyAddress < NativeMasterOnlyBase
    self.table_name = :addresses
    belongs_to :native_user, foreign_key: :user_id
  end

  class NativeUnreplicatedUser < NativeUnreplicatedRecord
    self.table_name = :users
  end

  class NativeUnreplicatedAddress < NativeUnreplicatedRecord
    self.table_name = :addresses
  end
end

if db_config['adapter'] == "postgresql"
  reset_seq_sql = "select setval('addresses_id_seq',(select max(id) from addresses))"
  if ActiveRecord::Base.respond_to?(:with_connection)
    ActiveRecord::Base.with_connection { |c| c.execute(reset_seq_sql) }
  else
    ActiveRecord::Base.connection.execute(reset_seq_sql)
  end
end

require "support/extend_minitest"
require "support/active_record_logger"
