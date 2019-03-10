require 'ruby-prof'
require_relative '../task-1'

def profile(mode:)
  puts "*** Measure mode #{mode} ***"

  RubyProf.measure_mode = Object.const_get("RubyProf::#{mode.upcase}")

  result = RubyProf.profile do
    work
  end

  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
end

profile(mode: :allocations)
profile(mode: :wall_time)
