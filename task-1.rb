# frozen_string_literal: true
# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'csv'
require 'ruby-prof'
require 'minitest/autorun'

require 'benchmark'

def parse_user(id, first_name, last_name, *)
  {
    id: id,
    first_name: first_name,
    last_name: last_name,
  }
end

def parse_session(user_id, _, browser, time, date, *)
  {
    user_id: user_id,
    browser: browser.upcase,
    time: time.to_i,
    date: Date.parse(date).iso8601,
  }
end

def increase_user_sessions(user_stats)
  user_stats[:sessionsCount] ||= 0
  user_stats[:sessionsCount] += 1
end

def add_total_time(user_stats, session_time)
  user_stats[:totalTime] ||= 0
  user_stats[:totalTime] += session_time
end

def add_longest_session(user_stats, session_time)
  user_stats[:longestSession] ||= 0
  user_stats[:longestSession] = session_time if user_stats[:longestSession] < session_time
end

def add_user_browser(user_stats, browser)
  user_stats[:browsers] ||= ""
  user_stats[:browsers] = (user_stats[:browsers].split(', ') << browser).sort!.join(', ')
end

def set_used_ie(user_stats, browser)
  user_stats[:usedIE] ||= false
  user_stats[:usedIE] = true if browser.include?('INTERNET EXPLORER')
end

def set_always_chrome(user_stats, browser)
  user_stats[:alwaysUsedChrome] = true unless user_stats.key?(:alwaysUsedChrome)
  user_stats[:alwaysUsedChrome] = (user_stats[:alwaysUsedChrome] && (browser.include?('CHROME')))
end


def add_user_date(user_stats, date)
  user_stats[:dates] ||= []
  user_stats[:dates] << date
end

def produce_initial_report
  {
    totalUsers: 0,
    uniqueBrowsersCount: 0,
    totalSessions: 0,
    allBrowsers: "",
    usersStats: {}
  }
end

def increase_total_sessions(report)
  report[:totalSessions] += 1
end

def increase_total_users(report)
  report[:totalUsers] += 1
end

def prepare_user_mappings(report, session_to_user, user)
  key = "#{user[:first_name]} #{user[:last_name]}"
  id = user[:id]

  session_to_user[id] ||= key
  report[:usersStats][key] ||= {}
end

def format_user_stats(user_stats)
  user_stats.each do |(_, stat)|
    stat[:totalTime] = "#{stat[:totalTime]} min."
    stat[:longestSession] = "#{stat[:longestSession]} min."
    stat[:dates].sort!.reverse!
  end
end

def set_unique_browser_stat(report, uniqueBrowsers)
  report[:uniqueBrowsersCount] = uniqueBrowsers.length
  report[:allBrowsers] = uniqueBrowsers.to_a.sort!.join(',')
end

def write_json(file_name, report)
  File.open(file_name, 'w') do |file|
    JSON.dump(report, file)
    file.write("\n")
  end
end

def work
  report = produce_initial_report
  uniqueBrowsers = Set.new
  session_to_user = {}

  File.open('data.txt') do |file|
    csv = CSV.new(file)

    csv.each do |(type, *row)|
      case type
      when 'session'
        session = parse_session(*row)
        increase_total_sessions(report)

        uniqueBrowsers << session[:browser]
        key = session_to_user[session[:user_id]]

        user_stats = report[:usersStats][key]
        browser = session[:browser]
        session_time = session[:time]

        increase_user_sessions(user_stats)
        add_total_time(user_stats, session_time)
        add_longest_session(user_stats, session_time)
        add_user_browser(user_stats, browser)
        set_used_ie(user_stats, browser)
        set_always_chrome(user_stats, browser)
        add_user_date(user_stats, session[:date])
      when 'user'
        user = parse_user(*row)

        increase_total_users(report)
        prepare_user_mappings(report, session_to_user, user)
      end
    end
  end

  format_user_stats(report[:usersStats])
  set_unique_browser_stat(report, uniqueBrowsers)

  write_json('result.json', report)
end

def memory_profiler(&block)
  block.call

  puts "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

def ruby_prof_profiler(&block)
  result = RubyProf.profile do
    block.call
  end

  File.open "./profile/profile_graph.html", 'w+' do |file|
    RubyProf::GraphHtmlPrinter.new(result).print(file)
  end

  File.open("./profile/profile_callstack.html", "w+") do |file|
    RubyProf::CallStackPrinter.new(result).print(file)
  end
end

def time_profiler(&block)
  time = Benchmark.realtime do
    block.call
  end

  puts "Time: #{time}"
end

def gc_profiler(&block)
  block.call

  puts GC.stat
end

# memory_profiler do
#   time_profiler do
#     work
#   end
# end

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

  def test_result
    work

    expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
    assert_equal expected_result, File.read('result.json')
  end
end
