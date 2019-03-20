# Deoptimized version of homework task

require 'json'

def parse_user(user)
  {
    full_name: user[2] + ' ' + user[3]
  }
end

def parse_session(session)
  {
    session_id: session[2],
    browser: session[3],
    time: session[4],
    date: session[5],
  }
end

def add_parameters(object)
  return {} unless object
  sessions = object[1][:sessions]
  user = object[1][:user]
  array_time = sessions.map { |s| s[:time].to_i }
  array_browser = sessions.map { |s| s[:browser] }
  {
    user[:full_name] => {
      sessionsCount: sessions.count,
      totalTime: array_time.sum.to_s + ' min.',
      longestSession: array_time.max.to_s + ' min.',
      browsers: array_browser.map { |b| b.upcase}.sort.join(', '),
      usedIE: (array_browser.map { |b| b.upcase =~ /INTERNET EXPLORER/ }.include? (0)),
      alwaysUsedChrome: sessions.map{|s| s[:browser]}.all? { |b| b.upcase =~ /CHROME/ },
      dates: sessions.map{|s| s[:date] }.sort.reverse
    }
  }

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

def work(file: 'data_large2.txt', output: './response/result.json')
  return false unless file
  file_lines = File.read(file).split("\n")

  data = {}
  report = {
    totalUsers: 0,
    uniqueBrowsersCount: 0,
    totalSessions: 0,
    allBrowsers: [],
    usersStats: {}
  }
  sessions_browsers = []

  file_lines.each_slice(10000) do |line_slice|
    line_slice.each do |line|
      cols = line.split(',')
      id = cols[1]
      data[id] ||= {}
      if cols[0] == 'user'
        report[:totalUsers] += 1
        if  data[id].nil?
          report[:usersStats].merge!(add_parameters(data.shift))
        end
        data[id][:user] = parse_user(cols)
      else
        report[:totalSessions] += 1
        data[id][:sessions] ||= []
        data[id][:sessions] << parse_session(cols)
        sessions_browsers << cols[3]
      end
    end
    report[:usersStats].merge!(add_parameters(data.shift))
  end

  report[:uniqueBrowsersCount] = sessions_browsers.uniq.count
  report[:totalSessions] = sessions_browsers.count
  report[:allBrowsers] =
    sessions_browsers
      .map { |b| b.upcase }
      .sort
      .uniq
      .join(',')

  File.write(output, "#{report.to_json}\n")
end
