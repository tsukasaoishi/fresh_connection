# frozen_string_literal: true
require 'active_support'

ActiveSupport.on_load(:active_record) do
  if ActiveRecord::VERSION::MAJOR < 7
    FreshConnection.deprecator.warn(
      "Support for ActiveRecord < 7.0 (current: #{ActiveRecord::VERSION::STRING}) is deprecated " \
      "and will be removed in FreshConnection 3.2.0. Please upgrade to Rails 7.0 or later."
    )
  end

  if (ActiveRecord::VERSION::MAJOR == 6 && ActiveRecord::VERSION::MINOR == 0) ||
     FreshConnection::RailsReplica.send(:legacy_connection_handling?)
    if respond_to?(:connection_handlers) && connection_handlers.empty?
      w_role = ActiveRecord.respond_to?(:writing_role) ? ActiveRecord.writing_role : writing_role
      self.connection_handlers = { w_role => ActiveRecord::Base.default_connection_handler }
    end
  end

  require 'fresh_connection/extend/ar_base'
  require 'fresh_connection/extend/ar_relation'
  require 'fresh_connection/extend/ar_relation_merger'
  require 'fresh_connection/extend/ar_statement_cache'

  ActiveRecord::Base.extend FreshConnection::Extend::ArBase
  ActiveRecord::Base.singleton_class.prepend FreshConnection::Extend::ArQueryCache
  if FreshConnection::RailsReplica.supported? && ActiveRecord::Base.respond_to?(:connected_to)
    ActiveRecord::Base.singleton_class.prepend FreshConnection::Extend::ArConnectedTo
  end
  if ActiveRecord::Base.respond_to?(:cached_find_by, true)
    ActiveRecord::Base.singleton_class.prepend FreshConnection::Extend::ArCachedFindBy
  end
  ActiveRecord::Relation.prepend FreshConnection::Extend::ArRelation
  ActiveRecord::Relation::Merger.prepend FreshConnection::Extend::ArRelationMerger
  ActiveRecord::StatementCache.prepend FreshConnection::Extend::ArStatementCache

  if ActiveRecord::VERSION::MAJOR >= 7
    require 'fresh_connection/extend/ar_connection_handler'
    ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(
      FreshConnection::Extend::ArConnectionHandler
    )

    require 'fresh_connection/connection_specification/rails_70'
    FreshConnection::ConnectionSpecification.include(
      FreshConnection::ConnectionSpecification::Rails70
    )
  elsif ActiveRecord::VERSION::MAJOR == 6 && ActiveRecord::VERSION::MINOR == 1
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

  # Extend any supported adapters that were already loaded before `require "fresh_connection"`
  {
    "Mysql2Adapter" => ['fresh_connection/extend/adapters/m2_adapter', :M2Adapter],
    "TrilogyAdapter" => ['fresh_connection/extend/adapters/trilogy_adapter', :TrilogyAdapter],
    "PostgreSQLAdapter" => ['fresh_connection/extend/adapters/pg_adapter', :PgAdapter]
  }.each do |adapter_const, (req_path, ext_const)|
    next if ActiveRecord::ConnectionAdapters.autoload?(adapter_const)
    next unless ActiveRecord::ConnectionAdapters.const_defined?(adapter_const, false)

    require req_path
    klass = ActiveRecord::ConnectionAdapters.const_get(adapter_const, false)
    ext = FreshConnection::Extend.const_get(ext_const, false)
    unless klass.include?(ext)
      klass.prepend FreshConnection::Extend::BaseAdapter
      klass.prepend ext
    end
  end
end
