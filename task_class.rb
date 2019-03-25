# Deoptimized version of homework task
# frozen_string_literal: true

require 'json'
require 'date'
require 'pry'
require 'csv'

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
      'sessions' => []
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
      user_key = "#{user['first_name']}" + ' ' + "#{user['last_name']}"
      report['usersStats'][user_key] ||= {}
      report['usersStats'][user_key]['sessionsCount'] = collect_session_count(user['sessions'])
      report['usersStats'][user_key]['totalTime'] = collect_session_time(user['sessions'])
      report['usersStats'][user_key]['longestSession'] = collect_session_longest(user['sessions'])
      report['usersStats'][user_key]['browsers'] = collect_browsers(user['sessions'])
      report['usersStats'][user_key]['usedIE'] = collect_ie_usage(user['sessions'])
      report['usersStats'][user_key]['alwaysUsedChrome'] = collect_if_only_chrome_used(user['sessions'])
      report['usersStats'][user_key]['dates'] = collect_session_dates(user['sessions'])
    end
  end

  # Собираем количество сессий по пользователям
  def collect_session_count(sessions)
    sessions.count
  end

  # Собираем количество времени по пользователям
  def collect_session_time(sessions)
    sessions.sum {|s| s['time'].to_i }.to_s + ' min.'
  end

  # Выбираем самую длинную сессию пользователя
  def collect_session_longest(sessions)
    sessions.map {|s| s['time'].to_i}.max.to_s + ' min.'
  end

  # Браузеры пользователя через запятую
  def collect_browsers(sessions)
    sessions.map {|s| s['browser'].upcase}.sort.join(', ')
  end

  # Хоть раз использовал IE?
  def collect_ie_usage(sessions)
    !!sessions.find {|s| s['browser'] =~ /INTERNET EXPLORER/i }
  end

  # Всегда использовал только Chrome?
  def collect_if_only_chrome_used(sessions)
    browsers = sessions.map {|s| s['browser']}.uniq
    browsers.count == 1 && browsers.first =~ /CHROME/i
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  def collect_session_dates(sessions)
    sessions.map{|s| s['date']}.sort {|a,b| b <=> a}
  end

  def prepare_data(filename, users, sessions)
    File.open(filename) do |file|
      file.lazy.each_slice(2000) do |lines|
        lines.each do |row|
          row = row.chomp.split(',')
          if row[0] == 'session'
            session = parse_session(row)
            sessions << session
            users[session['user_id'].to_i]['sessions'] << session
          else
            users << parse_user(row)
          end
        end
      end
    end
    # file_lines = File.open(filename, "r")
    # file_lines.each_line do |line|
    #   cols = line.chomp.split(',')
    #   if cols[0] == 'session'
    #     sessions << parse_session(cols)
    #   else
    #     users << parse_user(cols)
    #   end
    # end
    # CSV.foreach(filename) do |row|
    #   if row[0] == 'session'
    #     sessions << parse_session(row)
    #   else
    #     users << parse_user(row)
    #   end
    # end
    # File.open(filename, 'r') do |file|
    #   csv = CSV.new(file, headers: true)
    #   sum = 0
    #
    #   while row = csv.shift
    #     if row[0] == 'session'
    #       sessions << parse_session(row)
    #     else
    #       users << parse_user(row)
    #     end
    #   end
    # end
  end

  def work(filename:)
    users = []
    sessions = []
    t1=Time.now
    prepare_data(filename, users, sessions)
    puts Time.now-t1

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
      uniqueBrowsers << browser unless uniqueBrowsers.include?(browser)
    end

    report['uniqueBrowsersCount'] = uniqueBrowsers.count

    report['totalSessions'] = sessions.count

    report['allBrowsers'] =
      sessions
        .map { |s| s['browser'].upcase }
        .sort
        .uniq
        .join(',')

    # Статистика по пользователям
    users_objects = []
t2=Time.now
    # users.each do |user|
    #   user_object = User.new(attributes: user, sessions: user['sessions'])
    #   users_objects << user_object
    # end
    puts Time.now - t2
    collect_stats_from_users(report, users)

    File.write('result.json', "#{report.to_json}\n")
  end
end
