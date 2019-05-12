require 'ruby-prof'
require_relative 'task-1'

parser = Parser.new()
result = RubyProf.profile do
  parser.work('tmp/data_small.txt') # 1MB
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

# run separately
printer = RubyProf::DotPrinter.new(result)
printer.print(File.open("ruby_prof_allocations_profile.dot", "w+"))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("ruby_prof_graph_allocations_profile.html", "w+"))

# ruby ruby_prof.rb
# dot -Tpng ruby_prof_allocations_profile.dot > ruby_prof.png
# brew install imgcat
# imgcat ruby_prof.png

# run separately
# qcachegrind tmp/profile.callgrind.out.92522
OUTPUT_DIR = 'tmp/'
printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: OUTPUT_DIR, profile: 'profile')