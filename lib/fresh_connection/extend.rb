require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  require 'fresh_connection/extend/ar_base'
  require 'fresh_connection/extend/ar_relation'
  require 'fresh_connection/extend/ar_relation_merger'
  require 'fresh_connection/extend/ar_abstract_adapter'
  require 'fresh_connection/extend/ar_statement_cache'

  ActiveRecord::Base.extend FreshConnection::Extend::ArBase
  ActiveRecord::Relation.send :prepend, FreshConnection::Extend::ArRelation
  ActiveRecord::Relation::Merger.send :prepend, FreshConnection::Extend::ArRelationMerger
  ActiveRecord::StatementCache.send :prepend, FreshConnection::Extend::ArStatementCache
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send :prepend, FreshConnection::Extend::ArAbstractAdapter

  ActiveRecord::Base.establish_fresh_connection
end
