require 'benchmark'
require './task-1'

arr = []

from = 10_000
to   = 15_000
step = 1000

(from..to).step(step) do |lines_num|
  system "zcat data_large.txt.gz | head -n #{lines_num} > data.txt"

  time = Benchmark.realtime { work }.round(2)

  puts "[#{lines_num}/#{to}] performed in #{time} s."

  arr << time.round(2)
end

avg = arr.reduce(:+) / arr.size

puts "Average time between #{from} and #{to} lines with step #{step}:\n#{avg}"
