require_relative 'task_class'
require 'stackprof'
require 'ruby-prof'

#StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
result = RubyProf.profile do
  TaskClass.new.work(filename: ARGV[0])
end

printer = RubyProf::DotPrinter.new(result)
printer.print(File.open("tmp/ruby_prof_allocations_profile.dot", "w+"))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("tmp/ruby_prof_graph_allocations_profile.html", "w+"))
