# rubocop:disable all
# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'

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
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
  }
end

def parse_session(session)
  fields = session.split(',')
  parsed_result = {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5],
  }
end

def collect_stats_from_users(report, users_objects) #, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(calc_stat(user))
  end
end

def calc_stat(user)
  time = time_from_sesions(user)
  user_browsers = browsers_list(user)
  is_used_ie = used_ie(user_browsers)
  {
    'sessionsCount': sessions_count(user),
    'totalTime' => total_time(time),
    'longestSession' => longest_session(time),
    'browsers' => browsers(user_browsers),
    'usedIE' => is_used_ie,
    'alwaysUsedChrome' => is_used_ie ? false : always_used_chrome(user_browsers),
    'dates' => dates(user)
  }
end

def sessions_count(user)
  user.sessions.count
end

def time_from_sesions(user)
  user.sessions.map {|s| s['time']}.map {|t| t.to_i}
end

def total_time(time)
  time.sum.to_s + ' min.'
end

def longest_session(time)
  time.max.to_s + ' min.'
end

def browsers_list(user)
  user.sessions.map {|s| s['browser']}.map {|b| b.upcase}.sort
end

def browsers(browsers)
  browsers.join(', ')
end

def used_ie(browsers)
  browsers.any? { |b| b =~ /INTERNET EXPLORER/ }
end

def always_used_chrome(browsers)
  # browsers.uniq.count == 1 && browsers.first =~ /CHROME/
  browsers.all? { |b| b.upcase =~ /CHROME/ }
end

def dates(user)
  user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 }
end

def work(file='data.txt')
  file_lines = File.read(file).split("\n")

  users = []
  sessions = []

  file_lines.each do |line|
    cols = line.split(',')
    users = users + [parse_user(line)] if cols[0] == 'user'
    sessions = sessions + [parse_session(line)] if cols[0] == 'session'
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

  # Подсчёт количества уникальных браузеров
  uniqueBrowsers = []
  sessions.each do |session|
    browser = session['browser']
    uniqueBrowsers += [browser] if uniqueBrowsers.all? { |b| b != browser }
  end

  report['uniqueBrowsersCount'] = uniqueBrowsers.count

  report['totalSessions'] = sessions.count

  report['allBrowsers'] =
    sessions
      .map { |s| s['browser'] }
      .map { |b| b.upcase }
      .sort
      .uniq
      .join(',')

  # Статистика по пользователям
  users_objects = []

  sessions_by_user = sessions.group_by{|h| h["user_id"]}
  sessions_by_user.default = []

  users.each do |user|
    attributes = user
    user_sessions = sessions_by_user[user['id']]
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects = users_objects + [user_object]
  end

  report['usersStats'] = {}

  collect_stats_from_users(report, users_objects)

  File.write('result.json', "#{report.to_json}\n")
end
