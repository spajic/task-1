require_relative './user'
require_relative './parser'
require 'json'

class ReportGenerator
  USER = 'user'.freeze
  COMMA_SEPARATOR = ','.freeze
  COMMA_WITH_SPACE = ', '.freeze
  MIN = ' min.'.freeze
  SPACE = ' '.freeze

  attr_reader :users, :sessions

  def work(file_name)
    @users = []
    @sessions = []
    users_count = 0
    sessions_count = 0

    File.open(file_name) do |f|
      user = nil
      f.each_line do |line|
        if line.start_with?(USER)
          users_count += 1
          users << user = User.new(attributes: Parser.parse_user(line))
        else
          parsed_session = Parser.parse_session(line)
          user.sessions << parsed_session
          sessions << parsed_session
          sessions_count += 1
        end
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

    report = {
      totalUsers: users_count,
      uniqueBrowsersCount: unique_browsers.count,
      totalSessions: sessions_count,
      allBrowsers: unique_browsers.join(COMMA_SEPARATOR),
      usersStats: {}
    }

    sessions_stats(report, users)
    browsers_stats(report, users)

    # Даты сессий через запятую в обратном порядке в формате iso8601
    collect_stats_from_users(report, users) do |user|
      { dates: user.sessions.map { |s| s[:date].chomp }.sort_by! { |d| d }.reverse! }
    end

    File.write('result.json', "#{report.to_json}\n")
    # JSON.dump(report, File.open('result.json', 'w'))
  end

  private

  # Собираем количество сессий по пользователям
  # Собираем количество времени по пользователям
  # Выбираем самую длинную сессию пользователя
  def sessions_stats(report, users)
    collect_stats_from_users(report, users) do |user|
      time = user.sessions.map { |s| s[:time].to_i }
      { sessionsCount: time.count, totalTime: time.sum.to_s << MIN, longestSession: time.max.to_s << MIN }
    end
  end

  def browsers_stats(report, users)
    collect_stats_from_users(report, users) do |user|
      { browsers: user.sessions.map { |s| s[:browser].upcase }.sort!.join(COMMA_WITH_SPACE) }
    end

    # Хоть раз использовал IE?
    collect_stats_from_users(report, users) do |user|
      { usedIE: user.sessions.map { |s| s[:browser]}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ } }
    end

    # Всегда использовал только Chrome?
    collect_stats_from_users(report, users) do |user|
      { alwaysUsedChrome: user.sessions.map { |s| s[:browser]}.all? { |b| b.upcase =~ /CHROME/ } }
    end
  end

  def unique_browsers
    @unique_browsers ||= sessions
      .map { |s| s[:browser].upcase }
      .sort!
      .uniq!
  end

  def collect_stats_from_users(report, users, &block)
    users.each do |user|
      user_key = "#{user.attributes[:first_name]} #{user.attributes[:last_name]}"
      report[:usersStats][user_key] ||= {}
      report[:usersStats][user_key].merge!(block.call(user))
    end
  end
end
