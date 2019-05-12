require 'memory_profiler'
require_relative 'task-1'

parser = Parser.new()
report = MemoryProfiler.report do
  parser.work('tmp/data_small.txt') # 1MB
end
report.pretty_print(scale_bytes: true)