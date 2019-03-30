require 'set'
require 'oj'
require 'progress_bar'

COMMA = ','.freeze
COMMA_SPACE = ', '.freeze
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
  fields = str.split(COMMA)

  user.id = fields[1]
  user.key = fields[2] + SPACE + fields[3]
  user
end

def parse_session(str, session)
  fields = str.split(COMMA)

  session.browser = fields[3].upcase!
  session.time = fields[4].to_i
  session.date = fields[5].strip
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

  def add_user_to_report(user, report_file, last_item)
    report_file.write("\"#{user.key}\":")

    user_report = {
      sessionsCount: user_sessions_count,
      totalTime: total.to_s << MIN,
      longestSession: max.to_s << MIN,
      browsers: browsers.sort!.join(COMMA_SPACE),
      usedIE: use_ie,
      alwaysUsedChrome: always_chrome,
      dates: dates.sort!.reverse!,
    }

    report_file.write(Oj.dump(user_report, mode: :compat))

    if !last_item
      report_file.write(COMMA)
    end

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

def work(file_name = 'data.txt', show_progress = false)
  user = nil
  session = nil
  users_count = 0

  unique_browsers = Set.new
  total_sessions = 0
  user_report = UserReport.new
  bytes_read = 0

  bar = show_progress ? ProgressBar.new(File.size(file_name) / 1024.0) : nil

  File.open('result.json', 'w') do |report_file|
    report_file.write('{"usersStats":{')

    IO.foreach(file_name) do |line|
      if line.start_with?(USER)
        if user != nil
          user_report.add_user_to_report(user, report_file, false)
        else
          user = User.new(nil, nil)
          session = Session.new(nil, nil, nil)
        end

        user = parse_user(line, user)
        users_count += 1

        if show_progress
          bar.increment!(bytes_read / 1024.0)
          bytes_read = 0
        end

        # if users_count % 1000 == 0
        #   puts "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0)
        # end
      else
        session = parse_session(line, session)
        unique_browsers << session.browser
        total_sessions += 1
        user_report.handle_session(session)
      end

      bytes_read += line.size
    end

    # add lastest user
    user_report.add_user_to_report(user, report_file, true)

    if show_progress
      bar.increment!(bytes_read)
    end

    report_file.write('},')

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

    report = {
      totalUsers: users_count,
      uniqueBrowsersCount: unique_browsers.count,
      totalSessions: total_sessions,
      allBrowsers: unique_browsers.to_a.sort.join(COMMA),
    }

    stats_line = Oj.dump(report, mode: :compat)[1..-2]

    report_file.write(stats_line)
    report_file.write('}')
  end
end
