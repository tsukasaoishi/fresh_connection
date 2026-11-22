# frozen_string_literal: true

module FreshConnection
  module RailsReplica
    MYSQL_CONNECTION_LOST_PATTERN = /lost connection|server has gone away|can't connect|closed mysql connection/i
    private_constant :MYSQL_CONNECTION_LOST_PATTERN

    class << self
      def supported?
        ActiveRecord::VERSION::MAJOR >= 7 ||
          (ActiveRecord::VERSION::MAJOR == 6 && ActiveRecord::VERSION::MINOR >= 1)
      end

      def use_rails_replica?(model)
        return false unless supported?
        return false if FreshConnection.custom_connection_manager?
        return false if model.explicit_fresh_connection?

        !reading_pool_for(model).nil?
      end

      def legacy_replica_enabled?(model)
        return true unless supported?
        return false if use_rails_replica?(model)
        return true if FreshConnection.custom_connection_manager?
        return true if model.explicit_fresh_connection?

        conn_class = connection_class_for(model)
        is_primary = (conn_class == ActiveRecord::Base) ||
          (conn_class.respond_to?(:primary_class?) && conn_class.primary_class?)
        return false unless is_primary

        reading_pool_for(ActiveRecord::Base).nil?
      end

      def reading_role
        if ActiveRecord.respond_to?(:reading_role)
          ActiveRecord.reading_role
        elsif ActiveRecord::Base.respond_to?(:reading_role)
          ActiveRecord::Base.reading_role
        else
          :reading
        end
      end

      def writing_role
        if ActiveRecord.respond_to?(:writing_role)
          ActiveRecord.writing_role
        elsif ActiveRecord::Base.respond_to?(:writing_role)
          ActiveRecord::Base.writing_role
        else
          :writing
        end
      end

      def in_reading_role?(model)
        return false unless supported?

        model_role = model.respond_to?(:current_role) ? model.current_role : ActiveRecord::Base.current_role
        model_role == reading_role
      end

      def any_reading_or_preventing_writes?
        return false unless supported?

        if !legacy_connection_handling? && ActiveRecord::Base.respond_to?(:connected_to_stack, true)
          stack = ActiveRecord::Base.send(:connected_to_stack)
          return false if stack.nil? || stack.empty?

          r_role = reading_role
          return stack.any? { |entry| entry[:role] == r_role || entry[:prevent_writes] == true }
        end

        (ActiveRecord::Base.respond_to?(:current_role) && ActiveRecord::Base.current_role == reading_role) ||
          (ActiveRecord::Base.respond_to?(:current_preventing_writes) && ActiveRecord::Base.current_preventing_writes)
      end

      def reading_pool_for(model)
        return nil unless supported?

        role = reading_role
        conn_class = connection_class_for(model)
        spec_name = conn_class.connection_specification_name
        shard = current_shard_for(model)

        if legacy_connection_handling?
          handler = ActiveRecord::Base.connection_handlers[role]
          handler && handler.retrieve_connection_pool(spec_name, role: role, shard: shard)
        else
          ActiveRecord::Base.connection_handler.retrieve_connection_pool(spec_name, role: role, shard: shard)
        end
      rescue ActiveRecord::ConnectionNotDefined, ActiveRecord::ConnectionNotEstablished
        nil
      end

      def writing_pool_for(model)
        return model.connection_pool unless supported?

        role = writing_role
        conn_class = connection_class_for(model)
        spec_name = conn_class.connection_specification_name
        shard = current_shard_for(model)

        if legacy_connection_handling?
          handler = ActiveRecord::Base.connection_handlers[role]
          handler && handler.retrieve_connection_pool(spec_name, role: role, shard: shard)
        else
          ActiveRecord::Base.connection_handler.retrieve_connection_pool(spec_name, role: role, shard: shard)
        end
      rescue ActiveRecord::ConnectionNotDefined, ActiveRecord::ConnectionNotEstablished
        nil
      end

      def with_reading(model, &block)
        pool = reading_pool_for(model)
        return yield unless pool

        track_reading_pool(pool) if FreshConnection.put_aside

        target = connected_to_target(model)
        role = reading_role
        if target.respond_to?(:current_role) && target.current_role == role
          return yield
        end

        with_internal_connected_to do
          target.connected_to(role: role, prevent_writes: true, &block)
        end
      end

      def with_writing(model, &block)
        role = writing_role
        model_role = model.respond_to?(:current_role) ? model.current_role : ActiveRecord::Base.current_role
        preventing = model.respond_to?(:current_preventing_writes) && model.current_preventing_writes

        if model_role == role && !preventing &&
           (!ActiveRecord::Base.respond_to?(:current_role) || ActiveRecord::Base.current_role == role) &&
           !any_reading_or_preventing_writes?
          return yield
        end

        with_internal_connected_to do
          ActiveRecord::Base.connected_to(role: role, prevent_writes: false, &block)
        end
      end

      def with_user_connected_to(klass, role)
        if internal_connected_to?
          state_set(:fresh_connection_internal_connected_to, false)
          return yield
        end
        return yield if role.nil?

        stack = user_connected_to_stack
        stack.push({ klass: klass, role: role.to_sym })
        yield
      ensure
        stack.pop if stack
      end

      def explicitly_connected_to_writing?(model)
        return false unless supported?

        stack = state_get(:fresh_connection_user_connected_to_stack)
        return false if stack.nil? || stack.empty?

        conn_class = connection_class_for(model)
        role = writing_role

        stack.reverse_each do |entry|
          entry_klass = entry[:klass]
          matches = (entry_klass == ActiveRecord::Base) ||
            (entry_klass == conn_class) ||
            (conn_class == ActiveRecord::Base && entry_klass.respond_to?(:primary_class?) && entry_klass.primary_class?)
          return entry[:role] == role if matches
        end

        false
      end

      def active_connection_for(pool)
        return nil unless pool

        active = pool.active_connection?
        return nil unless active
        return active if active.respond_to?(:open_transactions)

        if pool.respond_to?(:active_connection)
          pool.active_connection
        elsif pool.respond_to?(:lease_connection)
          pool.lease_connection
        else
          pool.connection
        end
      end

      def pool_in_transaction?(pool)
        conn = active_connection_for(pool)
        return false unless conn

        conn.open_transactions > 0
      end

      def in_transaction?(model)
        pool = writing_pool_for(model)
        return true if pool_in_transaction?(pool)

        if supported?
          writing_pools.any? do |other_pool|
            other_pool != pool && same_writing_database?(pool, other_pool) && pool_in_transaction?(other_pool)
          end
        else
          base_pool = writing_pool_for(ActiveRecord::Base)
          base_pool && base_pool != pool && pool_in_transaction?(base_pool)
        end
      end

      def recovery?(model, exception: nil)
        return false if defined?(ActiveRecord::ConnectionNotDefined) && exception.is_a?(ActiveRecord::ConnectionNotDefined)

        pool = reading_pool_for(model)
        return false unless pool

        conn = active_connection_for(pool)
        if connection_error?(exception)
          if conn
            safe_put_aside_pool!(pool)
          else
            discard_dead_idle_connections!(pool)
          end
          return true
        end

        if conn
          return false if (conn.active? rescue false)

          safe_put_aside_pool!(pool)
          return true
        end

        # Rails 7.2+ with_connection already returned or discarded the connection on exception.
        # Inspect idle connections directly without calling pool.with_connection (which auto-verifies/reconnects).
        candidates = pool.synchronize do
          pool.connections.select { |c| !c.in_use? && !c.transaction_open? }
        end

        # If the pool has no connections left (e.g. broken connection was already discarded), allow retry.
        return true if candidates.empty?

        discard_dead_connections_from_candidates!(pool, candidates)
      end

      def put_aside!
        return unless supported?
        return unless FreshConnection.put_aside

        tracked_pools = take_tracked_reading_pools
        reading_pools.each do |pool|
          put_aside_pool!(pool, was_tracked: tracked_pools.include?(pool))
        end
      end

      def put_aside_pool!(pool, was_tracked: false)
        return unless pool

        conn = active_connection_for(pool)
        if conn
          return if conn.transaction_open?

          pool.remove(conn)
          conn.expire if conn.respond_to?(:expire)
          conn.disconnect! rescue nil
        elsif was_tracked
          idle = pool.synchronize do
            pool.connections.find { |c| !c.in_use? && !c.transaction_open? }
          end
          if idle
            removed = pool.synchronize do
              if !idle.in_use? && !idle.transaction_open? && pool.connections.include?(idle)
                pool.remove(idle)
                true
              end
            end
            idle.disconnect! rescue nil if removed
          end
        end
      end

      def clear_all_connections!
        return unless supported?

        reading_pools.each(&:disconnect!)
      end

      def with_reading_pools_query_cache(enable:, dirties: true, &block)
        return yield unless supported?

        pools = reading_pools
        return yield if pools.empty?

        apply_query_cache_to_pools(pools, 0, enable, dirties, &block)
      end

      def connection_class_for(model)
        if model.respond_to?(:connection_class_for_self)
          model.connection_class_for_self
        elsif model.respond_to?(:connection_classes)
          model.connection_classes
        else
          klass = model
          while klass != ActiveRecord::Base && !klass.abstract_class?
            klass = klass.superclass
          end
          klass
        end
      end

      private

      def safe_put_aside_pool!(pool)
        put_aside_pool!(pool)
      rescue StandardError
        nil
      end

      def connected_to_target(model)
        return ActiveRecord::Base if legacy_connection_handling?

        conn_class = connection_class_for(model)
        if conn_class == ActiveRecord::Base
          ActiveRecord::Base
        elsif conn_class.abstract_class? &&
              (conn_class.name == conn_class.connection_specification_name ||
               (conn_class.respond_to?(:primary_class?) && conn_class.primary_class?))
          conn_class
        else
          ActiveRecord::Base
        end
      end

      def legacy_connection_handling?
        if ActiveRecord.respond_to?(:legacy_connection_handling)
          ActiveRecord.legacy_connection_handling
        elsif ActiveRecord::Base.respond_to?(:legacy_connection_handling)
          ActiveRecord::Base.legacy_connection_handling
        else
          false
        end
      end

      def current_shard_for(model)
        if model.respond_to?(:current_shard)
          model.current_shard
        elsif ActiveRecord::Base.respond_to?(:default_shard)
          ActiveRecord::Base.default_shard
        else
          :default
        end
      end

      def same_writing_database?(pool_a, pool_b)
        return false if pool_a.nil? || pool_b.nil?
        return false unless pool_a.respond_to?(:db_config) && pool_b.respond_to?(:db_config)

        cfg_a = pool_a.db_config
        cfg_b = pool_b.db_config
        return false unless cfg_a.name == cfg_b.name

        if cfg_a.respond_to?(:configuration_hash) && cfg_b.respond_to?(:configuration_hash)
          ha = cfg_a.configuration_hash
          hb = cfg_b.configuration_hash
          %i[adapter host port database].all? { |k| ha[k] == hb[k] }
        else
          true
        end
      end

      def connection_error?(exception)
        return false unless exception

        current = exception
        visited = 0
        while current && visited < 5
          return true if match_connection_error_class?(current)

          current = current.respond_to?(:cause) ? current.cause : nil
          visited += 1
        end
        false
      end

      def match_connection_error_class?(err)
        return false if defined?(ActiveRecord::ConnectionNotDefined) && err.is_a?(ActiveRecord::ConnectionNotDefined)
        return true if err.is_a?(ActiveRecord::ConnectionNotEstablished)
        return true if defined?(ActiveRecord::ConnectionFailed) && err.is_a?(ActiveRecord::ConnectionFailed)
        return true if defined?(::Mysql2::Error::ConnectionError) && err.is_a?(::Mysql2::Error::ConnectionError)
        return true if defined?(::Mysql2::Error) && err.is_a?(::Mysql2::Error) && err.message.to_s.match?(MYSQL_CONNECTION_LOST_PATTERN)
        return true if defined?(::Trilogy::ConnectionError) && err.is_a?(::Trilogy::ConnectionError)
        return true if defined?(::Trilogy::EOFError) && err.is_a?(::Trilogy::EOFError)
        return true if defined?(::Trilogy::TimeoutError) && err.is_a?(::Trilogy::TimeoutError)
        return true if defined?(::Trilogy::SyscallError) && err.is_a?(::Trilogy::SyscallError)
        return true if defined?(::PG::ConnectionBad) && err.is_a?(::PG::ConnectionBad)
        return true if defined?(::PG::UnableToSend) && err.is_a?(::PG::UnableToSend)
        return true if defined?(::PG::AdminShutdown) && err.is_a?(::PG::AdminShutdown)
        return true if defined?(::PG::CrashShutdown) && err.is_a?(::PG::CrashShutdown)
        return true if defined?(::PG::CannotConnectNow) && err.is_a?(::PG::CannotConnectNow)

        false
      end

      def reading_pools
        pools_for_role(reading_role)
      end

      def writing_pools
        pools_for_role(writing_role)
      end

      def pools_for_role(role)
        if legacy_connection_handling?
          handler = ActiveRecord::Base.connection_handlers[role]
          handler ? handler.connection_pool_list(role) : []
        else
          ActiveRecord::Base.connection_handler.connection_pool_list(role)
        end
      rescue StandardError
        []
      end

      def apply_query_cache_to_pools(pools, index, enable, dirties, &block)
        return yield if index >= pools.length

        pool = pools[index]
        next_step = -> { apply_query_cache_to_pools(pools, index + 1, enable, dirties, &block) }

        if enable
          if pool.respond_to?(:enable_query_cache)
            was_enabled = pool.respond_to?(:query_cache_enabled) && pool.query_cache_enabled
            begin
              pool.enable_query_cache(&next_step)
            ensure
              pool.clear_query_cache if !was_enabled && pool.respond_to?(:clear_query_cache)
            end
          elsif pool.respond_to?(:enable_query_cache!)
            was_enabled = pool.respond_to?(:query_cache_enabled) && pool.query_cache_enabled
            pool.enable_query_cache!
            begin
              next_step.call
            ensure
              unless was_enabled
                pool.disable_query_cache!
                active = active_connection_for(pool)
                active.clear_query_cache if active && active.respond_to?(:clear_query_cache)
              end
            end
          else
            next_step.call
          end
        else
          if pool.respond_to?(:disable_query_cache)
            if pool.method(:disable_query_cache).parameters.any? { |type, name| (type == :key || type == :keyreq) && name == :dirties }
              pool.disable_query_cache(dirties: dirties, &next_step)
            else
              pool.disable_query_cache(&next_step)
            end
          elsif pool.respond_to?(:disable_query_cache!)
            was_enabled = pool.respond_to?(:query_cache_enabled) && pool.query_cache_enabled
            pool.disable_query_cache!
            begin
              next_step.call
            ensure
              pool.enable_query_cache! if was_enabled
            end
          else
            next_step.call
          end
        end
      end

      def with_internal_connected_to
        prev = state_get(:fresh_connection_internal_connected_to)
        state_set(:fresh_connection_internal_connected_to, true)
        yield
      ensure
        state_set(:fresh_connection_internal_connected_to, prev)
      end

      def internal_connected_to?
        !!state_get(:fresh_connection_internal_connected_to)
      end

      def user_connected_to_stack
        stack = state_get(:fresh_connection_user_connected_to_stack)
        unless stack
          stack = []
          state_set(:fresh_connection_user_connected_to_stack, stack)
        end
        stack
      end

      def track_reading_pool(pool)
        tracked = state_get(:fresh_connection_tracked_reading_pools)
        unless tracked
          tracked = []
          state_set(:fresh_connection_tracked_reading_pools, tracked)
        end
        tracked << pool unless tracked.include?(pool)
      end

      def take_tracked_reading_pools
        tracked = state_get(:fresh_connection_tracked_reading_pools)
        state_set(:fresh_connection_tracked_reading_pools, nil)
        tracked || []
      end

      def discard_dead_idle_connections!(pool)
        candidates = pool.synchronize do
          pool.connections.select { |c| !c.in_use? && !c.transaction_open? }
        end
        discard_dead_connections_from_candidates!(pool, candidates)
      end

      def discard_dead_connections_from_candidates!(pool, candidates)
        return false if candidates.empty?

        # Check active? outside pool.synchronize to avoid holding pool mutex during network I/O
        dead = candidates.reject { |c| c.active? rescue false }
        return false if dead.empty?

        removed = pool.synchronize do
          dead.select do |c|
            if !c.in_use? && !c.transaction_open? && pool.connections.include?(c)
              pool.remove(c)
              true
            end
          end
        end
        removed.each { |c| c.disconnect! rescue nil }
        !removed.empty?
      end

      def state_get(key)
        if defined?(ActiveSupport::IsolatedExecutionState)
          ActiveSupport::IsolatedExecutionState[key]
        else
          Thread.current[key]
        end
      end

      def state_set(key, value)
        if defined?(ActiveSupport::IsolatedExecutionState)
          ActiveSupport::IsolatedExecutionState[key] = value
        else
          Thread.current[key] = value
        end
      end
    end
  end
end
