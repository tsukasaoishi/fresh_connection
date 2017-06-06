dbname          = 'fresh_connection_test_master'
replica1_dbname = 'fresh_connection_test_replica1'
replica2_dbname = 'fresh_connection_test_replica2'

pg_user = ENV['PG_USER'] || ENV['USER']
pg_pass = ENV['PG_PASS']

db_user = [ pg_user, pg_pass ].compact.join(':')
db_user += '@' if db_user

db_params = [ 'encoding=utf8', 'pool=5' ].join('&')

ENV['DB_ADAPTER']                = 'postgresql'
ENV['DB_USER']                   = pg_user
ENV['DATABASE_URL']              = "postgresql://#{db_user}localhost/#{dbname}?#{db_params}"
ENV['DATABASE_REPLICA_URL']      = "postgresql://#{db_user}localhost/#{replica1_dbname}?#{db_params}"
ENV['DATABASE_REPLICA1_URL']     = "postgresql://#{db_user}localhost/#{replica1_dbname}?#{db_params}"
ENV['DATABASE_REPLICA2_URL']     = "postgresql://#{db_user}localhost/#{replica2_dbname}?#{db_params}"
ENV['DATABASE_FAKE_REPLICA_URL'] = "postgresql://#{db_user}localhost/#{dbname}?#{db_params}"
