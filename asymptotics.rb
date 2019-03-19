require './task-1'
require 'benchmark/ips'
require 'ruby-prof'
require 'fileutils'

folder = ENV['STEP'] ? "metrics/optimization/#{ENV['STEP']}" : 'metrics/deoptimized'
desc   = ENV['DESC']

FileUtils.mkdir_p folder

# old_stdout = $stdout
# $stdout    = StringIO.new
# Benchmark.ips do |bench|
#   bench.warmup = 0
#   %w(80000 200000 1000000 2000000).each do |lines|
#     bench.report("Process #{lines}") { work(lines) }
#     bench.compare!
#   end
# end

# result  = $stdout.string
# File.write("#{folder}/README.md", "#{desc}\n Benchmarks\n #{result}")
# $stdout = old_stdout

# # CPU

# GC.disable
# RubyProf.measure_mode = RubyProf::WALL_TIME
# result = RubyProf.profile do
#   work('80000')
# end

# # printer = RubyProf::FlatPrinter.new(result)
# # printer.print(File.open("#{folder}/ruby_prof_cpu_flat.txt", "w+"))

# printer2 = RubyProf::GraphHtmlPrinter.new(result)
# printer2.print(File.open("#{folder}/ruby_prof_cpu_graph.html", "w+"))

# # printer3 = RubyProf::CallStackPrinter.new(result)
# # printer3.print(File.open("#{folder}/ruby_prof_cpu_callstack.html", "w+"))

# # printer4 = RubyProf::CallTreePrinter.new(result)
# # printer4.print(:path => "#{folder}/", :profile => 'callgrind')
# GC.enable

# # Run rbspy
# `LINES=80000 GS_DISABLE=1 rbspy record ruby task-1.rb --file #{folder}/rbspy`

#Memory
%w(80000 1000000 2000000).each do |lines|
  next if lines == '80000' || lines == '2000000'
  `LINES=#{lines} valgrind --tool=massif --massif-out-file="#{folder}/massif_#{lines}.out" 'ruby' task-1.rb`
end

# RubyProf.measure_mode = RubyProf::ALLOCATIONS
# result = RubyProf.profile do
#   work('80000')
# end
# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(path: "#{folder}/", profile: 'callgrind')
