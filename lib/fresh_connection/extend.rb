require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  require 'fresh_connection/extend/ar_base'
  require 'fresh_connection/extend/ar_relation'
  require 'fresh_connection/extend/connection_handler'
  require 'fresh_connection/extend/mysql2_adapter'
  require 'active_record/connection_adapters/mysql2_adapter'

  ActiveRecord::Base.extend FreshConnection::Extend::ArBase
  ActiveRecord::Relation.prepend FreshConnection::Extend::ArRelation
  ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend FreshConnection::Extend::ConnectionHandler
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend FreshConnection::Extend::Mysql2Adapter

  if defined?(ActiveRecord::StatementCache)
    require 'fresh_connection/extend/ar_statement_cache'
    ActiveRecord::StatementCache.prepend FreshConnection::Extend::ArStatementCache
  end

  ActiveRecord::Base.establish_fresh_connection
end
