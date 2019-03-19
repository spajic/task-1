require_relative 'task-1.rb'
require 'ruby-prof'

result = RubyProf.profile do
  work('data_large2.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(:path => ".", :profile => 'profile')
