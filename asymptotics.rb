require 'benchmark/ips'
require_relative 'task_1'

Benchmark.ips do |b|
  b.warmup = 0
  b.report('5k') { work('data/data_5k.txt') }
  b.report('10k') { work('data/data_10k.txt') }
  b.report('20k') { work('data/data_20k.txt') }
  b.report('30k') { work('data/data_30k.txt') }
  b.report('40k') { work('data/data_40k.txt') }

  b.compare!
end

