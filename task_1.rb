require 'set'
require 'oj'
require 'progress_bar'

SHOW_PROGRESS = ARGV[0] == nil
COLUMN = ','.freeze
COLUMN_SPACE = ', '.freeze
SPACE = ' '.freeze
USER = 'u'.freeze
SESSION = 's'.freeze
MIN = ' min.'.freeze

IE_MATCHER = 'INTERNET EXPLORER'
CHROME_MATCHER = 'CHROME'

class User
  attr_accessor :id, :key

  def initialize(id, key)
    @id = id
    @key = key
  end
end

class Session
  attr_accessor :browser, :time, :date

  def initialize(browser, time, date)
    @browser = browser
    @time = time
    @date = date
  end
end

def parse_user(str, user)
  fields = str.split(COLUMN)

  user.id = fields[1]
  user.key = fields[2] + SPACE + fields[3]

  # User.new(
  #   fields[1], # id
  #   fields[2] + SPACE + fields[3], # key = first_name + last_name
  # )
  user
end

def parse_session(str, session)
  fields = str.split(COLUMN)

  session.browser = fields[3].upcase!
  session.time = fields[4].to_i
  session.date = fields[5].strip

  # Session.new(
  #   # fields[1] # user_id
  #   # fields[2] # session_id
  #   fields[3].upcase!, # browser
  #   fields[4].to_i, # time
  #   fields[5].strip, # date
  # )

  session
end

class UserReport
  attr_accessor :user_sessions_count, :total, :max, :browsers, :use_ie, :always_chrome, :dates

  def initialize
    reset()
  end

  # Собираем количество сессий по пользователям
  # Собираем количество времени по пользователям
  # Выбираем самую длинную сессию пользователя
  # Браузеры пользователя через запятую
  # Хоть раз использовал IE?
  # Всегда использовал только Chrome?
  # Даты сессий через запятую в обратном порядке в формате iso8601
  def handle_session(session)
    @user_sessions_count += 1

    time = session.time
    @total += time

    if time > @max
      @max = time
    end

    browser = session.browser
    @browsers << browser

    if !@use_ie && browser.include?(IE_MATCHER)
      @use_ie = true
    end

    if @always_chrome && !browser.include?(CHROME_MATCHER)
      @always_chrome = false
    end

    @dates << session.date
  end

  def add_user_to_report(users_stats, user)
    user_report = {}
    user_report[:sessionsCount] = user_sessions_count
    user_report[:totalTime] = total.to_s << MIN
    user_report[:longestSession] = max.to_s << MIN
    user_report[:browsers] = browsers.sort!.join(COLUMN_SPACE)
    user_report[:usedIE] = use_ie
    user_report[:alwaysUsedChrome] = always_chrome
    user_report[:dates] = dates.sort!.reverse!
    users_stats[user.key] = user_report

    reset
  end

  private

  def reset
    @user_sessions_count = 0
    @total = 0
    @max = 0
    @browsers = []
    @use_ie = false
    @always_chrome = true
    @dates = []
  end
end

def work(file_name = 'data.txt')
  user = nil
  session = nil
  users_count = 0

  unique_browsers = Set.new
  total_sessions = 0
  users_stats = {}
  user_report = UserReport.new
  bytes_read = 0

  bar = SHOW_PROGRESS ? ProgressBar.new(File.size(file_name) / 1024.0) : nil

  File.readlines(file_name).each do |line|
    cols = line.split(COLUMN)

    if cols[0].start_with?(USER)
      if user != nil
        user_report.add_user_to_report(users_stats, user)
      else
        user = User.new(nil, nil)
        session = Session.new(nil, nil, nil)
      end

      user = parse_user(line, user)
      users_count += 1

      if SHOW_PROGRESS
        bar.increment!(bytes_read / 1024.0)
        bytes_read = 0
      end

      # puts "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0)
    else
      session = parse_session(line, session)
      unique_browsers << session.browser
      total_sessions += 1
      user_report.handle_session(session)
    end

    bytes_read += line.size
  end

  # add lastest user
  user_report.add_user_to_report(users_stats, user)

  if SHOW_PROGRESS
    bar.increment!(bytes_read)
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
  report[:totalUsers] = users_count
  report[:uniqueBrowsersCount] = unique_browsers.count
  report[:totalSessions] = total_sessions
  report[:allBrowsers] = unique_browsers.to_a.sort.join(COLUMN)
  report[:usersStats] = users_stats

  File.write('result.json', "#{Oj.dump(report, mode: :compat)}\n")
end
