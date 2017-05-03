dbname          = 'fresh_connection_test_master'
replica1_dbname = 'fresh_connection_test_replica1'
replica2_dbname = 'fresh_connection_test_replica2'

mysql_user = ENV['MYSQL_USER'] || 'root'
mysql_pass = ENV['MYSQL_PASS']

db_user = [ mysql_user, mysql_pass ].compact.join(':')
db_user += '@' if db_user

db_params = [ 'encoding=utf8', 'pool=5' ].join('&')

ENV['DB_ADAPTER']            = 'mysql2'
ENV['DB_USER']               = mysql_user
ENV['DATABASE_URL']          = "mysql2://#{db_user}localhost/#{dbname}?#{db_params}"
ENV['DATABASE_REPLICA_URL']  = "mysql2://#{db_user}localhost/#{replica1_dbname}?#{db_params}"
ENV['DATABASE_REPLICA1_URL'] = "mysql2://#{db_user}localhost/#{replica1_dbname}?#{db_params}"
ENV['DATABASE_REPLICA2_URL'] = "mysql2://#{db_user}localhost/#{replica2_dbname}?#{db_params}"

