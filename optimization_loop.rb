require 'benchmark/ips'
require_relative 'task_1'

def test_correctness
  puts `ruby task_1_spec.rb`

  if !$?.success?
    raise 'code broken!'
  end
end

def evaluate_metric
  GC.disable

  Benchmark.ips do |b|
    b.stats = :bootstrap
    b.confidence = 99

    b.report('10k') { work('data/data_10k.txt') }
  end
end

test_correctness
evaluate_metric
