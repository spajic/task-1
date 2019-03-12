require 'benchmark'
require_relative 'task_1'

data_file = ENV.fetch('DATA', 'data/data_40k.txt')

if ARGV[0] == 'profile'
  puts 'Profiling...'
  # GC.disable

  # require 'memory_profiler'
  # report = MemoryProfiler.report do
  #   work('data_medium.txt')
  # end
  # report.pretty_print(color_output: true, scale_bytes: true)

  # require 'stackprof'
  # StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
  #   work(data_file)
  # end

  require 'ruby-prof'
  RubyProf.measure_mode = RubyProf::MEMORY
  result = RubyProf.profile do
    work(data_file)
  end

  # printer = RubyProf::FlatPrinter.new(result)
  # printer.print(STDOUT)

  # printer = RubyProf::GraphPrinter.new(result)
  # printer.print(STDOUT, {})

  # printer = RubyProf::CallStackPrinter.new(result)
  # File.open('ruby-prof-call-stack.html', "w") do |f|
  #   printer.print(f, threshold: 0, min_percent: 0, title: "ruby_prof WALL_TIME")
  # end

  printer = RubyProf::CallTreePrinter.new(result)
  printer.print()
elsif ARGV[0] == 'benchmark'
  puts 'Benchmarking...'

  Benchmark.bm do |x|
    x.report { work(data_file) }
  end
else
  work(data_file, true)
end

 # bundle exec stackprof tmp/stackprof.dump --text --limit 20
