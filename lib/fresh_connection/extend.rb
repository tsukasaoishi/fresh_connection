require 'fresh_connection/extend/ar_base'
require 'fresh_connection/extend/ar_relation'
require 'fresh_connection/extend/connection_handler'
require 'active_record/connection_adapters/mysql2_adapter'
require 'fresh_connection/extend/mysql2_adapter'

module ActiveRecord
  Base.extend FreshConnection::Extend::ArBase
  Relation.send :prepend, FreshConnection::Extend::ArRelation
  ConnectionAdapters::ConnectionHandler.send :prepend, FreshConnection::Extend::ConnectionHandler
  ConnectionAdapters::Mysql2Adapter.send :prepend, FreshConnection::Extend::Mysql2Adapter

  if defined?(StatementCache)
    require 'fresh_connection/extend/ar_statement_cache'
    StatementCache.send :prepend, FreshConnection::Extend::ArStatementCache
  end

  Base.establish_fresh_connection
end
