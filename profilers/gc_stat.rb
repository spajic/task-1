require_relative '../task-1'

puts "old GC stat:\n #{GC.stat}"
work
puts "new GC stat:\n #{GC.stat}"
