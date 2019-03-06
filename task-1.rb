# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'

class User
  attr_reader :attributes, :sessions, :browsers, :time

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
    @browsers = sessions.map { |s| s['browser'] }.map(&:upcase).sort
    @time = sessions.map { |s| s['time'] }.map(&:to_i)
  end

  def total_time
    "#{time.sum} min."
  end

  def longest_session
    "#{time.max} min."
  end
end

def parse_user(user)
  {
    'id' => user[1],
    'first_name' => user[2],
    'last_name' => user[3],
    'age' => user[4]
  }
end

def parse_session(session)
  {
    'user_id' => session[1],
    'session_id' => session[2],
    'browser' => session[3],
    'time' => session[4],
    'date' => session[5]
  }
end

def collect_stats_from_users(report, users_objects)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = user_stats(user)
  end
end

def user_stats(user)
  {
    'sessionsCount' => user.sessions.count,
    'totalTime' => user.total_time,
    'longestSession' => user.longest_session,
    'browsers' => user.browsers.join(', '),
    'usedIE' => user.browsers.any? { |b| b =~ /INTERNET EXPLORER/ },
    'alwaysUsedChrome' => user.browsers.uniq.all? { |b| b =~ /CHROME/ },
    'dates' => user.sessions.map { |s| s['date'] }.sort.reverse.map { |d| Date.iso8601(d) }
  }
end

def work(file_name)
  file_lines = File.read(file_name).split("\n")

  users = {}
  sessions = {}

  file_lines.each do |line|
    cols = line.split(',')
    users[cols[1]] = parse_user(cols) if cols[0] == 'user'

    next unless cols[0] == 'session'

    id = cols[1]
    sessions[id] ||= []
    sessions[id] << parse_session(cols)
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
  report['totalUsers'] = users.keys.count
  all_browsers = sessions.values.flatten.map { |s| s['browser'] }

  # Подсчёт количества уникальных браузеров
  unique_browsers = all_browsers.uniq

  report['uniqueBrowsersCount'] = unique_browsers.count
  report['totalSessions'] = sessions.values.flatten.count
  report['allBrowsers'] = unique_browsers.map(&:upcase).sort.join(',')
  report['usersStats'] = {}

  # Статистика по пользователям
  users_objects = users.each.with_object([]) do |(user_id, attrs), arr|
    arr << User.new(attributes: attrs, sessions: sessions[user_id])
  end

  collect_stats_from_users(report, users_objects)

  File.open('result.json', 'w') do |file|
    file.write(report.to_json)
    file.write("\n")
  end
end
