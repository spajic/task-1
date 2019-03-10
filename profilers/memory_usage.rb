require_relative '../task-1.rb'

def print_memory_usage
  "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

puts "rss before: #{print_memory_usage}"
work
puts "rss after: #{print_memory_usage}"
