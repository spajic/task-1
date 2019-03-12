require 'minitest/autorun'
require 'benchmark'
require_relative 'task_1'

class PerformanceTest < Minitest::Test
  FILE_NAME = 'data/data_large.txt'

  def assert_lt(a, b)
    assert_operator a, :<, b
  end

  def test_result
    time = Benchmark.measure { work(FILE_NAME) }
    assert_lt time.real, 15
  end
end
