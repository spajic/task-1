# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'set'
require 'oj'

COLUMN = ','.freeze
COLUMN_SPACE = ', '.freeze
SPACE = ' '.freeze
USER = 'u'.freeze
SESSION = 's'.freeze
MIN = ' min.'.freeze

IE_MATCHER = 'INTERNET EXPLORER'
CHROME_MATCHER = 'CHROME'

class User
  attr_reader :id, :key, :sessions

  def initialize(id, key)
    @id = id
    @key = key
    @sessions = []
  end
end

class Session
  attr_reader :browser, :time, :date

  def initialize(browser, time, date)
    @browser = browser
    @time = time
    @date = date
  end
end

def parse_user(user)
  fields = user.split(COLUMN)

  User.new(
    fields[1], # id
    fields[2] + SPACE + fields[3], # key = first_name + last_name
  )
end

def parse_session(raw_session, users)
  fields = raw_session.split(COLUMN)

  session = Session.new(
    # fields[1] # user_id
    # fields[2] # session_id
    fields[3].upcase!, # browser
    fields[4].to_i, # time
    fields[5], # date
  )

  user_id = fields[1]
  users[user_id].sessions << session
  session
end

def collect_stats_from_users(report, users, &block)
  usersStats = report[:usersStats]

  users.values.each do |user|
    block.call(user, usersStats[user.key])
  end
end

def work(file_name = 'data.txt')
  file_lines = File.read(file_name).split("\n")

  users = {}
  uniqueBrowsers = Set.new

  file_lines.each do |line|
    cols = line.split(COLUMN)

    if cols[0].start_with?(USER)
      user = parse_user(line)
      users[user.id] = user
    else
      session = parse_session(line, users)
      uniqueBrowsers << session.browser
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
  report[:uniqueBrowsersCount] = uniqueBrowsers.count
  report[:totalSessions] = users.values.sum { |user| user.sessions.size }
  report[:allBrowsers] = uniqueBrowsers.to_a.sort.join(COLUMN)
  report[:usersStats] = Hash.new { |hash, key| hash[key] = {} }

  # Собираем количество сессий по пользователям
  # Собираем количество времени по пользователям
  # Выбираем самую длинную сессию пользователя
  # Браузеры пользователя через запятую
  # Хоть раз использовал IE?
  # Всегда использовал только Chrome?
  # Даты сессий через запятую в обратном порядке в формате iso8601
  collect_stats_from_users(report, users) do |user, user_report|
    total = 0
    max = 0
    browsers = []
    use_ie = false
    always_chrome = true
    dates = []

    user.sessions.each do |session|
      time = session.time
      total += time

      if time > max
        max = time
      end

      browser = session.browser
      browsers << browser

      if !use_ie && browser.include?(IE_MATCHER)
        use_ie = true
      end

      if always_chrome && !browser.include?(CHROME_MATCHER)
        always_chrome = false
      end

      dates << session.date
    end

    user_report[:sessionsCount] = user.sessions.count
    user_report[:totalTime] = total.to_s << MIN
    user_report[:longestSession] = max.to_s << MIN
    user_report[:browsers] = browsers.sort!.join(COLUMN_SPACE)
    user_report[:usedIE] = use_ie
    user_report[:alwaysUsedChrome] = always_chrome
    user_report[:dates] = dates.sort!.reverse!
  end

  File.write('result.json', "#{Oj.dump(report, mode: :compat)}\n")
end
