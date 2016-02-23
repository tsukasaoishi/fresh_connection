require "test_helper"

class ThreadSafeValueTest < Minitest::Test
  def setup
    @value = FreshConnection::ThreadSafeValue.new
  end

  test "store, get. all" do
    threads_num = 5
    threads = []
    threads_num.times do |i|
      threads << Thread.new(i) do |t_i|
        @value.store(t_i)
        assert_equal t_i, @value.fetch

        @value.fetch do |get_data|
          assert_equal t_i, get_data
        end
      end
    end

    threads.each{|t| t.join}

    @value.all do |data|
      assert_equal (0...threads_num).to_a, data.sort
    end
  end

  test "delete" do
    threads_num = 5
    threads = []
    threads_num.times do |i|
      threads << Thread.new(i) do |t_i|
        @value.store(t_i)

        @value.delete do |del_data|
          assert_equal t_i, del_data
        end
      end
    end

    threads.each{|t| t.join}

    assert_equal [], @value.all
  end

  test "get or store" do
    threads_num = 5
    threads = []
    threads_num.times do |i|
      threads << Thread.new(i) do |t_i|
        @value.fetch do |val|
          assert_nil val
          @value.store(t_i)
        end

        assert_equal t_i, @value.fetch
      end
    end
  end

  test "clear" do
    threads_num = 5
    threads = []
    threads_num.times do |i|
      threads << Thread.new(i) do |t_i|
        @value.store(t_i)
      end
    end

    @value.clear

    assert_equal [], @value.all
  end
end
