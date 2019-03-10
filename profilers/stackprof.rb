require 'stackprof'
require_relative '../task-1'

def profile(mode:)
  dump_file = "/tmp/stackprof_#{mode}.dump"

  StackProf.run(mode: mode, out: dump_file, raw: true) do
    work
  end

  puts "*** Stackprof #{mode} mode ***"
  system "stackprof #{dump_file} --text --limit 3"
  puts '=== Object#work ==='
  system %(stackprof #{dump_file} --method 'Object#work')
  puts '=== Object#collect_stats_from_users ==='
  system %(stackprof #{dump_file} --method 'Object#collect_stats_from_users')
end

profile(mode: :object)
profile(mode: :wall)
