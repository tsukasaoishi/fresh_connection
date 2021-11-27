# frozen_string_literal: true
require 'active_support'

ActiveSupport.on_load(:active_record) do
  if respond_to?(:connection_handlers) && connection_handlers.empty?
    self.connection_handlers = { writing_role => ActiveRecord::Base.default_connection_handler }
  end

  require 'fresh_connection/extend/ar_base'
  require 'fresh_connection/extend/ar_relation'
  require 'fresh_connection/extend/ar_relation_merger'
  require 'fresh_connection/extend/ar_statement_cache'

  ActiveRecord::Base.extend FreshConnection::Extend::ArBase
  ActiveRecord::Relation.prepend FreshConnection::Extend::ArRelation
  ActiveRecord::Relation::Merger.prepend FreshConnection::Extend::ArRelationMerger
  ActiveRecord::StatementCache.prepend FreshConnection::Extend::ArStatementCache

  if ActiveRecord::VERSION::MAJOR == 6 && ActiveRecord::VERSION::MINOR == 1
    require 'fresh_connection/extend/ar_connection_handler'
    ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(
      FreshConnection::Extend::ArConnectionHandler
    )

    require 'fresh_connection/connection_specification/rails_61'
    FreshConnection::ConnectionSpecification.include(
      FreshConnection::ConnectionSpecification::Rails61
    )
  else
    require 'fresh_connection/extend/ar_resolver'
    ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.prepend(
      FreshConnection::Extend::ArResolver
    )

    require 'fresh_connection/connection_specification/rails_60'
    FreshConnection::ConnectionSpecification.include(
      FreshConnection::ConnectionSpecification::Rails60
    )
  end
end
