require 'memory_profiler'
require_relative '../task-1.rb'

report = MemoryProfiler.report(trace: [String]) do
  work
end

report.pretty_print(scale_bytes: true)
