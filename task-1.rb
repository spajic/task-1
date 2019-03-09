# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'
require 'ruby-prof'
require 'benchmark'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(fields)
  {
    id:         fields[0],
    first_name: fields[1],
    last_name:  fields[2],
    age:        fields[3]
  }
end

def parse_session(fields)
  {
    user_id:    fields[0],
    session_id: fields[1],
    browser:    fields[2],
    time:       fields[3],
    date:       fields[4]
  }
end

def collect_stats_from_users(report, users_objects)
  users_objects.each do |user|
    user_key = "#{user.attributes[:first_name]} #{user.attributes[:last_name]}"

    report[:usersStats][user_key] ||= {}
    report[:usersStats][user_key]   = report[:usersStats][user_key].merge(yield(user))
  end
end

def work(file_path)
  users         = []
  user_sessions = {}

  File.foreach(file_path) do |line|
    type, *rest = line.split(',')
    case type
    when 'user'
      users << parse_user(rest)
    when 'session'
      session                  = parse_session(rest)
      user_id                  = session[:user_id]
      user_sessions[user_id] ||= []
      user_sessions[user_id]  << session
    end
  end

  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +

  report = {}

  report[:totalUsers] = users.count

  report[:uniqueBrowsersCount] = 0

  report[:totalSessions] = 0

  report[:allBrowsers] = Set.new

  # Статистика по пользователям
  users_objects = []

  users.each do |user_attrs|
    currnet_user_sessions = Array(user_sessions[user_attrs[:id]])
    user_object           = User.new(attributes: user_attrs, sessions: currnet_user_sessions)
    users_objects        << user_object
  end

  report[:usersStats] = {}

  collect_stats_from_users(report, users_objects) do |user|
    result = {
      sessionsCount:    user.sessions.size, # Собираем количество сессий по пользователям
      totalTime:        0, # Собираем количество времени по пользователям
      longestSession:   0, # Выбираем самую длинную сессию пользователя
      browsers:         [], # Браузеры пользователя через запятую
      usedIE:           false, # Хоть раз использовал IE?
      alwaysUsedChrome: true, # Всегда использовал только Chrome?
      dates:            [] # Даты сессий через запятую в обратном порядке в формате iso8601
    }
    chrome_regexp = /CHROME/
    ie_regexp     = /INTERNET EXPLORER/

    user.sessions.each do |session|
      result[:dates] << Date.iso8601(session[:date])

      browser                     = session[:browser].upcase
      result[:alwaysUsedChrome] &&= browser.match?(chrome_regexp)
      result[:usedIE]           ||= browser.match?(ie_regexp)
      result[:browsers]          << browser

      time                    = session[:time].to_i
      result[:longestSession] = [result[:longestSession], time].max
      result[:totalTime]     += time

      report[:allBrowsers]   << browser
      report[:totalSessions] += 1
    end

    result[:dates].sort! { |d1, d2| d2 <=> d1 }
    result.merge!(
      totalTime:        "#{result[:totalTime]} min.",
      longestSession:   "#{result[:longestSession]} min.",
      browsers:         result[:browsers].sort!.join(', ')
    )
  end

  report[:uniqueBrowsersCount] = report[:allBrowsers].size # Подсчёт количества уникальных браузеров
  report[:allBrowsers]         = report[:allBrowsers].sort.join(',')

  File.write('result.json', "#{report.to_json}\n")
end

module MemoryMeasure
  def self.call
    `ps -o rss= -p #{Process.pid}`.to_i
  end
end

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
    work('data.txt')

    expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
    assert_equal expected_result, File.read('result.json')
  end
end

if ENV['MEASURE']
  puts '=' * 20
  before_mem = after_mem = profiling_result = nil
  time = Benchmark.realtime do
    before_mem = MemoryMeasure.call
    profiling_result = RubyProf.profile { work(ENV['MEASURE']) }
    after_mem = MemoryMeasure.call
  end

  puts "Time taken: #{time.round(2)}"

  mem_diff = after_mem - before_mem
  puts "RSS diff #{mem_diff} KB"
  puts '=' * 20

  postfix = RubyProf.measure_mode == RubyProf::MEMORY ? 'memory' : 'time'
  printer = RubyProf::CallTreePrinter.new(profiling_result)
  printer.print(path: '.', profile: "profile_#{postfix}")
end
