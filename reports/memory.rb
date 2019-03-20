require_relative '../task-1.rb'
require 'benchmark'

def print_memory_usage
  "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

time = Benchmark.realtime do
  puts  "rss after concatenation: #{print_memory_usage}"
  work(file: '../data_large2.txt', output: '../response/result.json')
  puts  "rss after concatenation: #{print_memory_usage}"
end

puts "Finish in #{time.round(2)}"
