$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fresh_connection'
require 'benchmark/ips'
require 'active_record'
require 'mysql2'

class ActiveRecord::Base
  establish_connection(
    adapter: 'mysql2',
    encoding: 'utf8',
    database: 'kaeruspoon_development',
    pool: 5,
    username: 'root',
    password: '',
    socket: '/tmp/mysql.sock',
    slave: { encoding: 'utf8' }
  )
end

class Article < ActiveRecord::Base
end

Benchmark.ips do |x|
  x.report("find") { Article.take }
end
