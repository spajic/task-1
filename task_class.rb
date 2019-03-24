# Deoptimized version of homework task
# frozen_string_literal: true

require 'json'
require 'date'
require 'pry'

class TaskClass
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
      'age' => fields[4],
    }
  end

  def parse_session(fields)
    {
      'user_id' => fields[1],
      'session_id' => fields[2],
      'browser' => fields[3],
      'time' => fields[4],
      'date' => fields[5],
    }
  end

  def collect_stats_from_users(report, users_objects)
    report['usersStats'] = {}
    users_objects.each do |user|
      user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
      report['usersStats'][user_key] ||= {}
      report['usersStats'][user_key]['sessionsCount'] = collect_session_count(user)
      report['usersStats'][user_key]['totalTime'] = collect_session_time(user)
      report['usersStats'][user_key]['longestSession'] = collect_session_longest(user)
      report['usersStats'][user_key]['browsers'] = collect_browsers(user)
      report['usersStats'][user_key]['usedIE'] = collect_ie_usage(user)
      report['usersStats'][user_key]['alwaysUsedChrome'] = collect_if_only_chrome_used(user)
      report['usersStats'][user_key]['dates'] = collect_session_dates(user)
    end
  end

  # Собираем количество сессий по пользователям
  def collect_session_count(user)
    user.sessions.count
  end

  # Собираем количество времени по пользователям
  def collect_session_time(user)
    user.sessions.sum {|s| s['time'].to_i }.to_s + ' min.'
  end

  # Выбираем самую длинную сессию пользователя
  def collect_session_longest(user)
    user.sessions.map {|s| s['time']}.map {|t| t.to_i}.max.to_s + ' min.'
  end

  # Браузеры пользователя через запятую
  def collect_browsers(user)
    user.sessions.map {|s| s['browser']}.map {|b| b.upcase}.sort.join(', ')
  end

  # Хоть раз использовал IE?
  def collect_ie_usage(user)
    !!user.sessions.find { |s| s['browser'] == 'INTERNET EXPLORER' }
  end

  # Всегда использовал только Chrome?
  def collect_if_only_chrome_used(user)
    browsers = user.sessions.map {|s| s['browser']}.uniq
    browsers.count == 1 && browsers.first == 'CHROME'
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  def collect_session_dates(user)
    user.sessions.map{|s| s['date']}.sort {|a,b| b <=> a}
  end

  def work(filename:)
    file_lines = File.read(filename).split("\n")

    users = []
    sessions = []

    file_lines.each do |line|
      cols = line.split(',')
      users = users + [parse_user(cols)] if cols[0] == 'user'
      sessions = sessions + [parse_session(cols)] if cols[0] == 'session'
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

    users.each do |user|
      attributes = user
      user_sessions = sessions.select { |session| session['user_id'] == user['id'] }
      user_object = User.new(attributes: attributes, sessions: user_sessions)
      users_objects = users_objects + [user_object]
    end
    collect_stats_from_users(report, users_objects)

    File.write('result.json', "#{report.to_json}\n")
  end
end
