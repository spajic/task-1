require 'benchmark'
require_relative 'task-1'

time = Benchmark.realtime do
  puts "rss before parsing: #{"%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)}"

  parser = Parser.new()
  parser.work('tmp/data_small.txt') # 1MB
  
  puts "rss after parsing: #{"%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)}"
end
puts "Finish in #{time.round(2)}"
