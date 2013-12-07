module FreshConnection
  class SlaveConnection
    COUNT = :fresh_connection_access_count
    TARGET = :fresh_connection_access_target

    class << self
      attr_writer :ignore_models, :ignore_configure_connection, :master_clear_connection

      def connection
        slave_connection
      end

      def clear_all_connections!
        if @slave_connections.present?
          @slave_connections.each_value{|c| c && c.disconnect! rescue nil}
        end
        @slave_connections = {}
      end

      def slave_access
        access_in(:slave)
        yield
      ensure
        access_out
      end

      def master_access
        access_in(:master)
        yield
      ensure
        access_out
      end

      def force_master_access
        now_target = Thread.current[TARGET]
        Thread.current[TARGET] = :master
        yield
      ensure
        Thread.current[TARGET] = now_target
      end

      def slave_access?
        Thread.current[TARGET] == :slave
      end

      def ignore_model?(model_name)
        (@ignore_models || []).include?(model_name)
      end

      def ignore_configure_connection?
        !!@ignore_configure_connection
      end

      def master_clear_connection?
        @master_clear_connection || false
      end

      private

      def access_in(target)
        Thread.current[COUNT] = (Thread.current[COUNT] || 0) + 1
        Thread.current[TARGET] ||= target
      end

      def access_out
        Thread.current[COUNT] -= 1
        if Thread.current[COUNT] == 0
          Thread.current[TARGET] = nil
          Thread.current[COUNT] = nil
        end
      end


      def slave_connection
        @slave_connections ||= {}
        @slave_connections[current_thread_id] ||= new_connection
      end

      def new_connection
        ActiveRecord::Base.send("#{spec["adapter"]}_connection", spec)
      end

      def spec
        @spec ||= get_spec
      end

      def get_spec
        ret = ActiveRecord::Base.configurations[Rails.env]
        ret.merge(ret["slave"] || {})
      end

      def current_thread_id
        Thread.current.object_id
      end
    end
  end
end
