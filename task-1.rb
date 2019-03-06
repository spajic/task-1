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
    user_key = user.attributes['first_name'].to_s + ' ' + user.attributes['last_name'].to_s
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(yield(user))
  end
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

  report[:totalUsers] = users.keys.count

  # Подсчёт количества уникальных браузеров
  uniqueBrowsers = []
  sessions.values.flatten.each do |session|
    browser = session['browser']
    uniqueBrowsers += [browser] if uniqueBrowsers.all? { |b| b != browser }
  end

  report['uniqueBrowsersCount'] = uniqueBrowsers.count

  report['totalSessions'] = sessions.values.flatten.count

  report['allBrowsers'] =
    sessions.values.flatten
            .map { |s| s['browser'] }
            .map(&:upcase)
            .sort
            .uniq
            .join(',')

  # Статистика по пользователям
  users_objects = users.each.with_object([]) do |(user_id, attrs), arr|
    arr << User.new(attributes: attrs, sessions: sessions[user_id])
  end

  report['usersStats'] = {}

  # Собираем количество сессий по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { 'sessionsCount' => user.sessions.count }
  end

  # Собираем количество времени по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { 'totalTime' => user.sessions.map { |s| s['time'] }.map(&:to_i).sum.to_s + ' min.' }
  end

  # Выбираем самую длинную сессию пользователя
  collect_stats_from_users(report, users_objects) do |user|
    { 'longestSession' => user.sessions.map { |s| s['time'] }.map(&:to_i).max.to_s + ' min.' }
  end

  # Браузеры пользователя через запятую
  collect_stats_from_users(report, users_objects) do |user|
    { 'browsers' => user.sessions.map { |s| s['browser'] }.map(&:upcase).sort.join(', ') }
  end

  # Хоть раз использовал IE?
  collect_stats_from_users(report, users_objects) do |user|
    { 'usedIE' => user.sessions.map { |s| s['browser'] }.any? { |b| b.upcase =~ /INTERNET EXPLORER/ } }
  end

  # Всегда использовал только Chrome?
  collect_stats_from_users(report, users_objects) do |user|
    { 'alwaysUsedChrome' => user.sessions.map { |s| s['browser'] }.all? { |b| b.upcase =~ /CHROME/ } }
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  collect_stats_from_users(report, users_objects) do |user|
    { 'dates' => user.sessions.map { |s| s['date'] }.map { |d| Date.parse(d) }.sort.reverse.map(&:iso8601) }
  end

  File.write('result.json', "#{report.to_json}\n")
end
