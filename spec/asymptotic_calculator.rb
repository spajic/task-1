require_relative '../lib/parser'
require 'benchmark/ips'

$stdout = StringIO.new

Benchmark.ips do |bench|
  bench.config(warmup: 2, time: 2, stats: :bootstrap, confidence: 100)

  bench.report('65kb') { work('data_65kb.txt') }
  bench.report('125kb') { work('data_125kb.txt') }
  bench.report('250kb') { work('data_250kb.txt') }
  bench.report('0.5m') { work('data_05m.txt') }
  bench.report('1m') { work('data_1m.txt') }

  bench.compare!
end

$stdout.rewind

File.open("#{$optimizations_dir}/asymptotic.txt", 'w') { |f| f.write($stdout.read) }
