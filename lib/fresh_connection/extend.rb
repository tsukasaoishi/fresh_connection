require 'active_record'
require 'fresh_connection/extend/ar_base'
require 'fresh_connection/extend/ar_relation'

module ActiveRecord
  Base.extend FreshConnection::Extend::ArBase
  Relation.send :prepend, FreshConnection::Extend::ArRelation

  if defined?(StatementCache)
    require 'fresh_connection/extend/ar_statement_cache'
    StatementCache.send :prepend, FreshConnection::Extend::ArStatementCache
  end

  Base.establish_fresh_connection
end
