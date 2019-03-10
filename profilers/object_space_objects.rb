require_relative '../task-1'

def print_object_space_delta(before, after)
  puts "TOTAL:    #{after[:TOTAL] - before[:TOTAL]}"
  puts "T_STRING: #{after[:T_STRING] - before[:T_STRING]}"
  puts "T_ARRAY:  #{after[:T_ARRAY] - before[:T_ARRAY]}"
end

object_space_before = ObjectSpace.count_objects
work
print_object_space_delta(object_space_before, ObjectSpace.count_objects)
