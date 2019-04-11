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
    if line.start_with?(USER_PREFIX)
      users << parse_user(line)
      report[:totalUsers] += 1
    end

    if line.start_with?(SESSION_PREFIX)
      sessions << parse_session(line)
      report[:totalSessions] += 1
    end
  end

  uniqueBrowsers = []
  sessions.each do |session|
    browser = session[:browser]
    uniqueBrowsers += [browser] if uniqueBrowsers.all? { |b| b != browser }
  end

  report[:uniqueBrowsersCount] = uniqueBrowsers.count

  report['allBrowsers'] =
    sessions
      .map { |s| s[:browser] }
      .sort
      .uniq
      .join(',')

  # Статистика по пользователям
  users_objects = []

  users.each do |user|
    attributes = user
    user_sessions = sessions.select { |session| session[:user_id] == user[:id] }
    users_objects << User.new(attributes: attributes, sessions: user_sessions)
  end

  report['usersStats'] = {}

  counter = 0
  while report[:totalUsers] > counter
    u = users_objects.shift
    user_key = u.attributes[:name]
    report['usersStats'][user_key] = {
      'sessionsCount' => u.sessions.count,
      'totalTime' => u.sessions.map do |s|
        s[:time]
      end.map do |t|
        t.to_i
      end.sum.to_s + ' min.',
      'longestSession' => u.sessions.map {|s| s[:time]}.map {|t| t.to_i}.max.to_s + ' min.',
      'browsers' => u.sessions.map {|s| s[:browser]}.sort.join(', '),
      'usedIE' => u.sessions.map{|s| s[:browser]}.any? { |b| b =~ /INTERNET EXPLORER/ },
      'alwaysUsedChrome' => u.sessions.map{|s| s[:browser]}.all? { |b| b =~ /CHROME/ },
      'dates' => u.sessions.map! { |s| Date.strptime(s[:date], DATE_PATTERN) }.sort! {|a,b| b <=> a}
    }
    counter += 1
  end

  # Собираем количество сессий по пользователям

  File.write("result.json", "#{report.to_json}\n")
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
#   x.report('20k lines:') do
#     2.times do
#       work("sample_data/20000_lines.txt")
#     end
#   end
# end

require 'stackprof'

StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
  work("sample_data/20000_lines.txt")
end

profile_data = StackProf.run(mode: :object) do
  work("sample_data/20000_lines.txt")
end

StackProf::Report.new(profile_data).print_text
StackProf::Report.new(profile_data).print_graphviz

# def print_memory_usage
#   "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
# end

# puts "rss before: #{print_memory_usage}"
#   work("sample_data/20000_lines.txt")
# puts "rss after: #{print_memory_usage}"
