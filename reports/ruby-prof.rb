require_relative '../task-1.rb'
require 'ruby-prof'

result = RubyProf.profile do
  work(file: '../data.txt', output: '../response/result.json')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(:path => "../response", :profile => 'profile')
