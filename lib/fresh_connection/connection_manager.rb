module FreshConnection
  class ConnectionManager
    def slave_connection
      @slave_connections ||= {}
      @slave_connections[current_thread_id] ||= new_connection
    end

    def put_aside!
      if @slave_connections.present?
        @slave_connections.each_value{|c| c && c.disconnect! rescue nil}
      end
      @slave_connections = {}
    end

    private

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
