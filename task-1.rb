# frozen_string_literal: true

require 'json'
require 'date'
require 'pry'

DELIMITER = ','.freeze
USER_PREFIX = 'user,'.freeze
SESSION_PREFIX = 'session,'.freeze
DATE_PATTERN = '%Y-%m-%d'.freeze

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  fields = user.split(',')
  parsed_result = {
    id: fields[1],
    name: "#{fields[2]} #{fields[3]}",
    age: fields[4],
  }
end

def parse_session(session)
  fields = session.split(',')
  parsed_result = {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3].upcase!,
    time: fields[4],
    date: fields[5],
  }
end

def work(filename = 'data.txt')
  report = {
    totalUsers: 0,
    uniqueBrowsersCount: 0,
    totalSessions: 0,
  }
  users = []
  sessions = []

  File.foreach(filename) do |line|
    if line.start_with?(SESSION_PREFIX)
      sessions << parse_session(line)
      next if report[:totalSessions] += 1
    end

    if line.start_with?(USER_PREFIX)
      users << parse_user(line)
      report[:totalUsers] += 1
    end
  end


  all_browsers = []
  users_objects = []
  sessions_by_user = {}

  while sessions[0]
    sess = sessions.shift
    next unless sess
    sessions_by_user[sess[:user_id]] = sessions_by_user[sess[:user_id]] ? (sessions_by_user[sess[:user_id]] << sess) : [sess]
    all_browsers << sess[:browser]
  end

  report[:allBrowsers] = all_browsers
    .uniq!
    .sort!
    .join(',')

  report[:uniqueBrowsersCount] = all_browsers.size

  users.each do |user|
    attributes = user
    users_objects << User.new(attributes: attributes, sessions: sessions_by_user[user[:id]] || [])
  end

  report['usersStats'] = {}

  counter = 0
  while report[:totalUsers] > counter
    u = users_objects.shift
    user_key = u.attributes[:name]

    user_sessions_time = u.sessions.map { |s| s[:time].to_i }
    user_browsers = u.sessions.map { |s| s[:browser] }

    report['usersStats'][user_key] = {
      'sessionsCount' => u.sessions.count,
      'totalTime' => user_sessions_time.sum.to_s << ' min.',
      'longestSession' => user_sessions_time.max.to_s << ' min.',
      'browsers' => user_browsers.sort.join(', '),
      'usedIE' => !user_browsers.find { |b| b =~ /INTERNET EXPLORER/ }.nil?,
      'alwaysUsedChrome' => !user_browsers.find { |b| b !~ /CHROME/ },
      'dates' => u.sessions.map! do |s|
        Date.civil(s[:date][0,4].to_i, s[:date][5,2].to_i, s[:date][8,2].to_i)
      end.sort! {|a,b| b <=> a}
    }
    counter += 1
  end

  # Собираем количество сессий по пользователям

  File.write("result.json", report.to_json << "\n")
end

filenames = ['10_lines', '100_lines', '1000_lines', '10000_lines', '20000_lines']
# filenames = Array.new(5) { '100_lines' }
# filenames.each do |fn|
#   work("sample_data/#{fn}.txt")
# end
# require "benchmark/ips"
# require "benchmark"

# Benchmark.ips do |x|
#   filenames.each do |filename|
#     x.report(filename) do
#       work("sample_data/#{filename}.txt")
#     end
#   end
#   x.compare!
# end
#
# Benchmark.bmbm(2) do |x|
#   filenames.each do |fn|
#     x.report(fn) do
#       2.times do
#         work("sample_data/#{fn}.txt")
#       end
#     end
#   end
# end
#
# require "benchmark"

# Benchmark.bmbm(2) do |x|
#   x.report('Big file') do
#     work("data_large.txt")
#   end
# end

# require 'stackprof'

# StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
#   work("sample_data/20000_lines.txt")
# end

# profile_data = StackProf.run(mode: :object) do
#   work("sample_data/20000_lines.txt")
# end

# StackProf::Report.new(profile_data).print_text
# StackProf::Report.new(profile_data).print_graphviz

# def print_memory_usage
#   "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
# end

# puts "rss before: #{print_memory_usage}"
# work("data_large.txt")
# puts "rss after: #{print_memory_usage}"

# require 'memory_profiler'

# MemoryProfiler.start

# work("sample_data/20000_lines.txt")

# report = MemoryProfiler.stop
# report.pretty_print(scale_bytes: true)
#
# require 'ruby-prof'

# # profile the code
# result = RubyProf.profile do
#   work("sample_data/20000_lines.txt")
# end

# # print a graph profile to text
# printer = RubyProf::GraphPrinter.new(result)
# printer.print(STDOUT, {})
