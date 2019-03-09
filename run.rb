require 'benchmark'
require_relative 'task_1'

data_file = ENV.fetch('DATA', 'data/data_20k.txt')

if ARGV[0] == 'profile'
  puts 'Profiling...'
  require 'memory_profiler'
  require 'stackprof'

  # report = MemoryProfiler.report do
  #   work('data_medium.txt')
  # end

  # report.pretty_print(color_output: true, scale_bytes: true)

  StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
    work(data_file)
  end
elsif ARGV[0] == 'benchmark'
  puts 'Benchmarking...'

  Benchmark.bm do |x|
    x.report { work(data_file) }
  end
else
  work(data_file)
end

 # bundle exec stackprof tmp/stackprof.dump --text --limit 20
