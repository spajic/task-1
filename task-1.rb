# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'
require 'set'

COMMA_SEP = ','
COMMA_SPACE_SEP = ', '
IE_RE = /INTERNET EXPLORER/.freeze
CHROME_RE = /CHROME/.freeze

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  fields = user.split(COMMA_SEP)
  {
    id:         fields[1],
    first_name: fields[2],
    last_name:  fields[3],
    age:        fields[4]
  }
end

def parse_session(session)
  fields = session.split(COMMA_SEP)
  {
    user_id:    fields[1],
    session_id: fields[2],
    browser:    fields[3],
    time:       fields[4],
    date:       fields[5]
  }
end

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes[:first_name]} #{user.attributes[:last_name]}"
    report[:usersStats][user_key] ||= {}
    report[:usersStats][user_key].merge!(block.call(user))
  end
end

def work(input = 'data.txt', output = 'result.json')
  sessions = []
  users_objects = []
  uniqueBrowsers = Set.new

  lines = File.open(input)
  lines.each_line do |line|
    if line.start_with?('user')
      user_attrs = parse_user(line)
      @user = User.new(attributes: user_attrs, sessions: [])
      users_objects << @user
    end
    if line.start_with? 'session'
      session = parse_session(line)
      browser = session[:browser]
      uniqueBrowsers << browser
      sessions << session
      @user.sessions << session
    end
  end
  lines.close

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

  report[:totalUsers] = users_objects.count

  report[:uniqueBrowsersCount] = uniqueBrowsers.count

  report[:totalSessions] = sessions.count

  report[:allBrowsers] = uniqueBrowsers.map(&:upcase).sort.join(COMMA_SEP)

  report[:usersStats] = {}

  # Собираем количество сессий по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { sessionsCount: user.sessions.count }
  end

  # Собираем количество времени по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { totalTime: user.sessions.map { |s| s[:time] }.map! { |t| t.to_i }.sum.to_s + ' min.' }
  end

  # Выбираем самую длинную сессию пользователя
  collect_stats_from_users(report, users_objects) do |user|
    { longestSession: user.sessions.map { |s| s[:time] }.map! { |t| t.to_i }.max.to_s + ' min.' }
  end

  # Браузеры пользователя через запятую
  collect_stats_from_users(report, users_objects) do |user|
    { browsers: user.sessions.map { |s| s[:browser] }.map! { |b| b.upcase }.sort.join(COMMA_SPACE_SEP) }
  end

  # Хоть раз использовал IE?
  collect_stats_from_users(report, users_objects) do |user|
    { usedIE: user.sessions.map { |s| s[:browser] }.any? { |b| b.upcase =~ IE_RE } }
  end

  # Всегда использовал только Chrome?
  collect_stats_from_users(report, users_objects) do |user|
    { alwaysUsedChrome: user.sessions.map { |s| s[:browser] }.all? { |b| b.upcase =~ CHROME_RE } }
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  collect_stats_from_users(report, users_objects) do |user|
    { dates: user.sessions.map { |s| s[:date] }.map { |d| Date.parse(d).iso8601 }.sort.reverse }
  end

  File.write(output, "#{report.to_json}\n")
end

if $PROGRAM_NAME == __FILE__
  require 'benchmark'

  Benchmark.bm(14) do |b|
    b.report("100 users:") { work('data_100.txt'); puts "%d Mb" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024) }
    b.report("1.000 users:") { work('data_1000.txt'); puts "%d Mb" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024) }
    b.report("10.000 users:") { work('data_10000.txt'); puts "%d Mb" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024) }
  end

  require 'memory_profiler'
  report = MemoryProfiler.report do
    work('data_1000.txt')
  end

  report.pretty_print(detailed_report: true)
end
