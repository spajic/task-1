require 'benchmark'
require './task-1'

def allocated_memory
  `ps -o rss= -p #{Process.pid}`.to_i / 1024
end

def mac_os?
  RUBY_PLATFORM.match?(/darwin/)
end

from = 50_000
to   = 55_000
step = 1000

times = []
allocations = []

(from..to).step(step) do |lines_num|

  if mac_os?
    system "zcat < data_large.txt.gz | head -n #{lines_num} > data.txt"
  else
    system "zcat data_large.txt.gz | head -n #{lines_num} > data.txt"
  end

  time = Benchmark.realtime do
    memory = allocated_memory
    work
    allocations << allocated_memory - memory
  end.round(2)

  puts "#{lines_num} lines performed in #{time} s. + #{allocations.last}MB"

  times << time.round(2)
end

deltas = []

times.each_index do |i|
  break if times[i.next].nil?

  deltas << times[i.next] - times[i]
end

avg_delta = deltas.reduce(:+) / deltas.size
mem_delta = (allocations.reduce(:+) / allocations.size.to_f).round(2)

puts "Average period for each #{step} lines: #{avg_delta}s."
puts "Average memory allocation for each #{step} lines: #{mem_delta}MB"
