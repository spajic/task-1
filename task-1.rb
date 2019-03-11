# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'

IE_REGEX = /INTERNET EXPLORER/i.freeze
NOT_CHROME_REGEX = /(?<!chrome)\s\d+/i.freeze

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(fields)
  {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4]
  }
end

def parse_session(fields)
  {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5]
  }
end

def work
  users = []
  sessions = []

  File.open('data.txt', 'r').each do |line|
    cols = line.split(',')
    users << parse_user(cols) if line.start_with?('user')
    sessions << parse_session(cols) if line.start_with?('session')
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

  report['totalUsers'] = users.count

  # Подсчёт количества уникальных браузеров
  uniqueBrowsers = []
  sessions.each do |session|
    browser = session['browser']
    next if uniqueBrowsers.include?(browser)

    uniqueBrowsers << browser
  end

  report['uniqueBrowsersCount'] = uniqueBrowsers.count
  report['totalSessions'] = sessions.count
  report['allBrowsers'] = uniqueBrowsers.map(&:upcase).sort.join(',')

  # Статистика по пользователям
  users_objects = []

  grouped_sessions_by_user_id = sessions.group_by do |session|
    session['user_id']
  end

  users.each do |user|
    user_sessions = grouped_sessions_by_user_id[user['id']]
    user_object = User.new(attributes: user, sessions: Array(user_sessions))
    users_objects << user_object
  end

  report['usersStats'] = users_objects.each.with_object({}) do |user, hash|
    user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"

    longest_session = user.sessions.max { |a,b| a['time'].to_i <=> b['time'].to_i }
    user_browsers   = user.sessions.map {|s| s['browser'].upcase }.sort.join(', ')

    hash[user_key] = {
      # Собираем количество сессий по пользователям
      'sessionsCount' => user.sessions.count,
      # Собираем количество времени по пользователям
      'totalTime' => "#{user.sessions.sum { |s| s['time'].to_i }} min.",
      # Выбираем самую длинную сессию пользователя
      'longestSession' => "#{longest_session['time']} min.",
      # Браузеры пользователя через запятую
      'browsers' => user_browsers,
      # Хоть раз использовал IE?
      'usedIE' => user_browsers.match?(IE_REGEX),
      # Всегда использовал только Chrome?
      'alwaysUsedChrome' => !user_browsers.match?(NOT_CHROME_REGEX),
      # Даты сессий через запятую в обратном порядке в формате iso8601
      'dates' => user.sessions.map { |s| Date.iso8601(s['date']) }.sort.reverse_each.with_object([]) { |d, arr| arr << d }
    }
  end

  File.write('result.json', "#{report.to_json}\n")
end
