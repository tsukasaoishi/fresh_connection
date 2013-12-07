module FreshConnection
  class SlaveConnection
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
        slave_access_in
        yield
      ensure
        slave_access_out
      end

      def slave_access?
        Thread.current[:fresh_connection_slave_access] ||= false
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

      def slave_access_in
        Thread.current[:fresh_connection_slave_access] = true
      end

      def slave_access_out
        Thread.current[:fresh_connection_slave_access] = false
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
