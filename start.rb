require './spec/spec_helper'
require_relative './task-1'
require 'benchmark/ips'
require 'ruby-prof'

result = RubyProf.profile do
  work('./spec/fixtures/data_medium_01k.txt')
end

# printer = RubyProf::FlatPrinter.new(result)
# printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open("ruby_prof_allocations_profile.dot", "w+"))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("ruby_prof_graph_allocations_profile.html", "w+"))
