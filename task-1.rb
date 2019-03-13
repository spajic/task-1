# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'
require 'benchmark'
require 'memory_profiler'
require 'minitest/autorun'
require 'minitest/benchmark'
require 'set'
require 'ruby-prof'
# require 'stackprof'
RubyProf.measure_mode = RubyProf::MEMORY

USER_STR = 'user'.freeze
SESSION_STR = 'session'.freeze
MIN_STR = ' min.'.freeze
IE_REGEXP = /INTERNET EXPLORER/.freeze
CHROME_REGEXP = /CHROME/.freeze
COMA_SEP = ','.freeze
COMA_SPACE_SEP = ', '.freeze

def parse_user(fields)
  {
    id: fields[1],
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4]
  }
end

def parse_session(fields)
  {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3],
    time: fields[4],
    date: fields[5]
  }
end

def parse_file(file)
  users = {}
  sessions = {}
  total_sessions = 0

  File.open(file).each do |line|
    cols = line.split(COMA_SEP)
    users[cols[1]] = parse_user(cols) if cols[0] == USER_STR
    next unless cols[0] == SESSION_STR

    id = cols[1]
    sessions[id] ||= []
    total_sessions += 1
    sessions[id] << parse_session(cols)
  end
  { users: users, sessions: sessions, total_sessions: total_sessions }
end

def user_stat(_user, user_sesssions)
  sessions_times = user_sesssions.map { |s| s[:time].to_i }
  user_browsers = user_sesssions.map { |s| s[:browser].upcase }.sort

  {
    sessionsCount: user_sesssions.count,
    totalTime: sessions_times.sum.to_s + MIN_STR,
    longestSession: sessions_times.max.to_s + MIN_STR,
    browsers: user_browsers.join(COMA_SPACE_SEP),
    usedIE: user_browsers.any? { |b| b.match?(IE_REGEXP) },
    alwaysUsedChrome: user_browsers.all? { |b| b.match?(CHROME_REGEXP) },
    dates: user_sesssions.map { |s| Date.strptime(s[:date], "%Y-%m-%d") }.sort!.reverse.map! { |d| d.iso8601 }
  }
end

def work(file = 'data.txt')
  data = parse_file(file)
  users = data[:users]
  sessions = data[:sessions]
  total_sessions = data[:total_sessions]

  report = {}
  report[:totalUsers] = users.count

  uniqueBrowsers = Set.new

  sessions.values.flatten.each do |s|
    uniqueBrowsers.add(s[:browser].upcase)
  end

  report['uniqueBrowsersCount'] = uniqueBrowsers.count
  report['totalSessions'] = total_sessions
  report['allBrowsers'] = uniqueBrowsers.to_a.sort.join(COMA_SEP)

  # Статистика по пользователям
  report['usersStats'] = {}

  users.each do |u_id, user|
    user_key = "#{user[:first_name]} #{user[:last_name]}"
    user_sesssions = sessions[u_id]
    report['usersStats'][user_key] = user_stat(user, user_sesssions)
  end

  File.write('result.json', "#{report.to_json}\n")
end

# time = Benchmark.realtime do
#   work
# end
# puts "Finish in #{time.round(2)}"

# report = MemoryProfiler.report do
#   work
# end

# report.pretty_print
# result = RubyProf.profile do
#   work
# end

# printer = RubyProf::FlatPrinter.new(result)
# printer.print(File.open('ruby_prof_flat_allocations_profile.txt', 'w+'))

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open("ruby_prof_allocations_profile.dot", "w+"))

# printer = RubyProf::GraphHtmlPrinter.new(result)
# printer.print(File.open("ruby_prof_graph_allocations_profile.html", "w+"))
#
# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(:path => ".", :profile => 'profile')
class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
    File.write('data.txt',
'user,0,Leida,Cira,0
session,0,0,Safari 29,87,2016-10-23
session,0,1,Firefox 12,118,2017-02-27
session,0,2,Internet Explorer 28,31,2017-03-28
session,0,3,Internet Explorer 28,109,2016-09-15
session,0,4,Safari 39,104,2017-09-27
session,0,5,Internet Explorer 35,6,2016-09-01
user,1,Palmer,Katrina,65
session,1,0,Safari 17,12,2016-10-21
session,1,1,Firefox 32,3,2016-12-20
session,1,2,Chrome 6,59,2016-11-11
session,1,3,Internet Explorer 10,28,2017-04-29
session,1,4,Chrome 13,116,2016-12-28
user,2,Gregory,Santos,86
session,2,0,Chrome 35,6,2018-09-21
session,2,1,Safari 49,85,2017-05-22
session,2,2,Firefox 47,17,2018-02-02
session,2,3,Chrome 20,84,2016-11-25
')
  end

  def test_time
    time = Benchmark.realtime do
      work('data_10000.txt')
    end

    puts time
    assert_operator time, :<, 0.08
  end

  def test_result
    work
    expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
    assert_equal expected_result, File.read('result.json')
  end
end
