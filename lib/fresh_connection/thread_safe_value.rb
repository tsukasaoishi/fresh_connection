module FreshConnection
  class ThreadSafeValue
    def initialize
      @mutex = Mutex.new
      clear
    end

    def fetch
      synchronize do
        value = @data[current_thread_id]
        block_given? ? yield(value) : value
      end
    end

    def store(value)
      synchronize do
        @data[current_thread_id] = value
      end
    end

    def delete
      synchronize do
        value = @data.delete(current_thread_id)
        block_given? ? yield(value) : value
      end
    end

    def all
      synchronize do
        block_given? ? yield(@data.values) : @data.values
      end
    end

    def clear
      synchronize do
        @data = {}
      end
    end

    private

    def synchronize
      if @mutex.locked?
        yield
      else
        @mutex.synchronize { yield }
      end
    end

    def current_thread_id
      Thread.current.object_id
    end
  end
end
