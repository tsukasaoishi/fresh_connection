module FreshConnection
  class ConnectionManager
    def initialize
      @mutex = Mutex.new
    end

    def slave_connection
      @mutex.synchronize do
        @slave_connections ||= {}
        @slave_connections[current_thread_id] ||= new_connection
      end
    end

    def put_aside!
      @mutex.synchronize do
        @slave_connections ||= {}
        if c = @slave_connections.delete(current_thread_id)
          c.disconnect! rescue nil
        end
      end
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
