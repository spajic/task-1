# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'

COLUMN = ','.freeze
COLUMN_SPACE = ', '.freeze
SPACE = ' '.freeze
USER = 'user'.freeze
SESSION = 'session'.freeze
MIN = ' min.'.freeze

IE_MATCHER = /INTERNET EXPLORER/
CHROME_MATCHER = /CHROME/

FORMATTED_DATE_CACHE = {}

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  fields = user.split(COLUMN)
  parsed_result = {
    id: fields[1],
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4],
    key: fields[2] + SPACE + fields[3],
  }
end

def parse_session(session)
  fields = session.split(COLUMN)
  parsed_result = {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3].upcase!,
    time: fields[4].to_i,
    date: fields[5],
  }
end

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    report[:usersStats][user.attributes[:key]] ||= {}
    report[:usersStats][user.attributes[:key]].merge!(block.call(user))
  end
end

def format_date(s)
  # if FORMATTED_DATE_CACHE.include?(s)
  #   FORMATTED_DATE_CACHE[s]
  # else
  #   FORMATTED_DATE_CACHE[s] = Date.parse(s[:date]).iso8601
  # end
  Date.parse(s[:date]).iso8601
end

def work(file_name = 'data.txt')
  file_lines = File.read(file_name).split("\n")

  users = []
  sessions = []

  file_lines.each do |line|
    cols = line.split(COLUMN)

    if cols[0] == USER
      users << parse_user(line)
    end

    if cols[0] == SESSION
      sessions << parse_session(line)
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

  # Подсчёт количества уникальных браузеров
  uniqueBrowsers = []
  sessions.each do |session|
    browser = session[:browser]
    uniqueBrowsers += [browser] if uniqueBrowsers.all? { |b| b != browser }
  end

  report[:uniqueBrowsersCount] = uniqueBrowsers.count

  report[:totalSessions] = sessions.count

  report[:allBrowsers] =
    sessions
      .map { |s| s[:browser] }
      .sort
      .uniq
      .join(COLUMN)

  # Статистика по пользователям
  users_objects = []

  users.each do |user|
    attributes = user
    user_sessions = sessions.select { |session| session[:user_id] == user[:id] }
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects << user_object
  end

  report[:usersStats] = {}

  # Собираем количество сессий по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { sessionsCount: user.sessions.count }
  end

  # Собираем количество времени по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    total = 0
    user.sessions.each { |s| total += s[:time] }

    { totalTime: total.to_s << MIN }
  end

  # Выбираем самую длинную сессию пользователя
  collect_stats_from_users(report, users_objects) do |user|
    max = 0
    user.sessions.each { |s| s[:time] > max ? max = s[:time] : max }

    { longestSession: max.to_s << MIN }
  end

  # Браузеры пользователя через запятую
  collect_stats_from_users(report, users_objects) do |user|
    { browsers: user.sessions.map { |s| s[:browser] }.sort.join(COLUMN_SPACE) }
  end

  # Хоть раз использовал IE?
  collect_stats_from_users(report, users_objects) do |user|
    use_ie = false

    user.sessions.each do |s|
      if s[:browser] =~ IE_MATCHER
        use_ie = true
        break
      end
    end

    { usedIE: use_ie }
  end

  # Всегда использовал только Chrome?
  collect_stats_from_users(report, users_objects) do |user|
    always_chrome = true

    user.sessions.each do |s|
      if s[:browser] !~ CHROME_MATCHER
        always_chrome = false
        break
      end
    end

    { alwaysUsedChrome: always_chrome }
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  collect_stats_from_users(report, users_objects) do |user|
    { dates: user.sessions.map! { |s| s[:date] }.sort!.reverse! }
  end

  File.write('result.json', "#{report.to_json}\n")
end
