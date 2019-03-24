require_relative 'task_class'
#require 'memory_profiler'
require 'stackprof'
# require 'ruby-prof'
# require 'pry'

#report = MemoryProfiler.report do
StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
#result = RubyProf.profile do
  TaskClass.new.work(filename: ARGV[0])
end

#report.pretty_print(scale_bytes: true)
# profile_data = StackProf.run(mode: :object) do
#   TaskClass.new.work(filename: ARGV[0])
# end
# StackProf::Report.new(profile_data).print_graphviz


# printer = RubyProf::FlatPrinter.new(result)
# printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open("ruby_prof_allocations_profile.dot", "w+"))

# printer = RubyProf::GraphHtmlPrinter.new(result)
# printer.print(File.open("ruby_prof_graph_allocations_profile.html", "w+"))
