# frozen_string_literal: true

module FreshConnection
  module Extend
    module ArStatementCache
      if RUBY_VERSION >= "3.0"
        def execute(params, connection, **kwargs, &block)
          model = (defined?(@model) && @model) || klass
          if FreshConnection::AccessControl.managed? && FreshConnection::AccessControl.current_model == model
            return super(params, connection, **kwargs, &block)
          end

          model.all.manage_access do
            if FreshConnection::RailsReplica.use_rails_replica?(model)
              if model.respond_to?(:with_connection)
                model.with_connection { |conn| super(params, conn, **kwargs, &block) }
              else
                super(params, model.connection, **kwargs, &block)
              end
            else
              super(params, connection, **kwargs, &block)
            end
          end
        end
      else
        def execute(params, connection, *rest, &block)
          model = (defined?(@model) && @model) || klass
          if FreshConnection::AccessControl.managed? && FreshConnection::AccessControl.current_model == model
            return super(params, connection, *rest, &block)
          end

          model.all.manage_access do
            if FreshConnection::RailsReplica.use_rails_replica?(model)
              if model.respond_to?(:with_connection)
                model.with_connection { |conn| super(params, conn, *rest, &block) }
              else
                super(params, model.connection, *rest, &block)
              end
            else
              super(params, connection, *rest, &block)
            end
          end
        end
        ruby2_keywords :execute if respond_to?(:ruby2_keywords, true)
      end
    end
  end
end
