require 'stackprof'
require_relative 'task-1'

parser = Parser.new()
StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
  parser.work('tmp/data_small.txt') # 1MB
end

profile_data = StackProf.run(mode: :object) do
  # use your code here
  parser.work('tmp/data_small.txt')
end
puts "=======PRINT TEXT======"
StackProf::Report.new(profile_data).print_text
puts "=======PRINT METHOD======"
StackProf::Report.new(profile_data).print_method(/work/)
puts "=======PRINT GRAPHVIZ======"
StackProf::Report.new(profile_data).print_graphviz
# Stackprof ObjectAllocations and Flamegraph
# stackprof tmp/stackprof.dump --text --limit 3
# stackprof tmp/stackprof.dump --method 'Parser#collect_stats_from_users'
#
# Flamegraph
# raw: true

# stackprof --flamegraph tmp/stackprof.dump > tmp/flamegraph
# stackprof --flamegraph-viewer=tmp/flamegraph
# brew install graphviz
# dot -Tpng graphviz.dot > graphviz.png