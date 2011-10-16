module FreshConnection
  class SlaveConnection
    class << self
      def connection
        slave_connections[slave_pointer] ||= new_connection
      end

      def clear_all_connections!
        if @slave_connections.present?
          @slave_connections.values.each{|conns| conns.each{|c| c.disconnect!}}
        end
        @slave_connections = {}
      end

      def slave_access_in
        Thread.current[:slave_access] = true
      end

      def slave_access_out
        Thread.current[:slave_access] = false
      end

      def slave_access?
        Thread.current[:slave_access] ||= false
      end

      def shift_slave_pointer
        Thread.current[:slave_pointer] = slave_pointer + 1
        Thread.current[:slave_pointer] = 0 if slave_pointer > max_slave_pointer
      end
      
      private

      def new_connection
        ActiveRecord::Base.send("#{spec["adapter"]}_connection", spec)
      end

      def slave_connections
        @slave_connections ||= {}
        @slave_connections[current_thread_id] ||= []
      end


      def slave_pointer
        Thread.current[:slave_pointer] ||= 0
      end

      def max_slave_pointer
        @max_slave_pointer ||= (spec["max_connection"] || 1) - 1
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
