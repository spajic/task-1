module Work
  CHROME_REGEXP = /chrome/i
  IE_REGEXP = /internet explorer/i

  module_function

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

  def collect_stats_from_users(report, users_objects, &block)
    # stats_time = Benchmark.realtime do
    users_objects.each do |user|
      user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
      report['usersStats'][user_key] ||= {}
      report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))
    end
    # end
    # puts "Stats time #{stats_time.round(4)}"
  end

  def load_file(filename)
    file_lines = File.read(filename).split("\n")
    puts "Handle file_lines #{file_lines.size} count"

    users = []
    sessions = []

    sessions_by_user = {}
    uniq_browsers = Set.new

    # lines_handle_time = Benchmark.realtime do
    file_lines.each do |line|
      cols = line.split(',')
      case cols[0]
      when 'user'
        users.push(parse_user(cols))
      when 'session'
        session = parse_session(cols)
        sessions_by_user[session['user_id']] ||= []
        sessions_by_user[session['user_id']] << session
        uniq_browsers << session['browser']
        sessions << session
      end
    end
    # end

    # puts "Lines handled in #{lines_handle_time.round(4)}"
    [users, sessions, sessions_by_user, uniq_browsers]
  end

  def build_users(users, sessions_by_user)
    users_objects = []

    # build_users_time = Benchmark.realtime do
    users.each do |user|
      user_sessions = sessions_by_user[user['id']] || []
      user_object = User.new(attributes: user, sessions: user_sessions)
      users_objects.push(user_object)
    end
    # end
    # puts "Users builded in #{build_users_time.round(4)}"
    users_objects
  end

  def write_report(result_filename, report)
    File.write(result_filename, "#{report.to_json}\n")
  end

  def work(filename, result_filename)

    users, sessions, sessions_by_user, uniq_browsers = load_file(filename)
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

    puts "total users #{report[:totalUsers]}"

    # Подсчёт количества уникальных браузеров
    uniq_browsers_count_time = Benchmark.realtime do
      report['uniqueBrowsersCount'] = uniq_browsers.size
    end

    puts "uniq_browsers_count_time eq #{uniq_browsers_count_time.round(4)}"

    report['totalSessions'] = sessions.count

    all_browsers_time = Benchmark.realtime do
      report['allBrowsers'] = uniq_browsers.sort.map(&:upcase).join(',')
    end
    puts "all_browsers_time #{all_browsers_time.round(4)}"

    # Статистика по пользователям
    users_objects = build_users(users, sessions_by_user)

    report['usersStats'] = {}
    collect_stats_from_users(report, users_objects) do |user|
      {
        sessionsCount: user.sessions.count,
        totalTime: 0,
        longestSession: 0,
        browsers: [],
        usedIE: false,
        alwaysUsedChrome: true,
        dates: []
      }.tap do |result|

        user.sessions.each do |session|
          result[:totalTime] += session['time'].to_i
          result[:longestSession] = [session['time'].to_i, result[:longestSession]].max
          result[:browsers] << session['browser'].upcase
          result[:usedIE] ||= session['browser'].match?(IE_REGEXP)
          result[:alwaysUsedChrome] &&= session['browser'].match?(CHROME_REGEXP)
          result[:dates] << session['date']
        end

        result[:dates].sort!.reverse!
        result[:totalTime] = "#{result[:totalTime]} min."
        result[:longestSession] = "#{result[:longestSession]} min."
        result[:browsers] = result[:browsers].sort.join(', ')
      end
    end

    write_report(result_filename, report)
  end
end
