require 'active_record'
require 'fresh_connection/extend/ar_base'
require 'fresh_connection/extend/ar_relation'
require 'fresh_connection/extend/ar_relation_merger'
require 'fresh_connection/extend/ar_abstract_adapter'

module ActiveRecord
  Base.extend FreshConnection::Extend::ArBase
  Relation.send :prepend, FreshConnection::Extend::ArRelation
  Relation::Merger.send :prepend, FreshConnection::Extend::ArRelationMerger

  if defined?(StatementCache)
    require 'fresh_connection/extend/ar_statement_cache'
    StatementCache.send :prepend, FreshConnection::Extend::ArStatementCache
  end

  ConnectionAdapters::AbstractAdapter.send :prepend, FreshConnection::Extend::ArAbstractAdapter

  Base.establish_fresh_connection
end
