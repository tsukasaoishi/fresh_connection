require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  require 'active_record/connection_adapters/mysql2_adapter'

  ActiveRecord::Base.extend FreshConnection::Extend::ArBase
  ActiveRecord::Relation.__send__(:prepend, FreshConnection::Extend::ArRelation)

  ActiveRecord::ConnectionAdapters::ConnectionHandler.__send__(
    :prepend, FreshConnection::Extend::ConnectionHandler
  )

  ActiveRecord::ConnectionAdapters::Mysql2Adapter.__send__(
    :prepend, FreshConnection::Extend::Mysql2Adapter
  )

  if defined?(ActiveRecord::StatementCache)
    ActiveRecord::StatementCache.__send__(:prepend, FreshConnection::Extend::ArStatementCache)
  end

  ActiveRecord::Base.establish_fresh_connection
end
