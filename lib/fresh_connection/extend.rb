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

  require 'fresh_connection/extend/ar_connection_handler'
  ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(
    FreshConnection::Extend::ArConnectionHandler
  )

  major = ActiveRecord::VERSION::MAJOR
  minor = ActiveRecord::VERSION::MINOR

  if major == 6 && minor == 1
    require 'fresh_connection/connection_specification/rails_61'
    FreshConnection::ConnectionSpecification.include(
      FreshConnection::ConnectionSpecification::Rails61
    )
  elsif (major == 7 && minor == 2) || major == 8
    require 'fresh_connection/connection_specification/rails_72'
    FreshConnection::ConnectionSpecification.include(
      FreshConnection::ConnectionSpecification::Rails72
    )
  else
    raise "fresh_connection #{FreshConnection::VERSION} supports ActiveRecord 6.1, 7.2, 8.0, 8.1 (current: #{ActiveRecord::VERSION::STRING})"
  end
end
