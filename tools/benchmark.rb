require './spec/spec_helper'
require_relative '../task-1'
require 'benchmark'

time = Benchmark.realtime do
  work('./spec/fixtures/data_medium-10k.txt')
end.round(4)

puts "Takes #{time}"
