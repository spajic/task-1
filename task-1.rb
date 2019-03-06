# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'

def parse_user(fields)
  {
    id: fields[1],
    first_name: fields[2],
    last_name: fields[3],
    age: fields[4],
  }
end

def parse_session(fields)
  {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3].upcase!,
    time: fields[4],
    date: fields[5],
  }
end

def aggregate_user_stats(data)
  return {} unless data

  user = data[1][:user]
  sessions = data[1][:sessions]
  user_key = user[:first_name] << " " << user[:last_name]
  time = sessions.map {|s| s[:time].to_i }
  browsers = sessions.map { |s| s[:browser] }
  {
    user_key => {
      sessionsCount: sessions.count,
      totalTime: time.sum.to_s << ' min.',
      longestSession: time.max.to_s << ' min.',
      browsers: browsers.sort!.join(', '),
      usedIE: browsers.any? { |b| b.include?('INTERNET EXPLORER') },
      alwaysUsedChrome: browsers.all? { |b| b.include?('CHROME')},
      dates: sessions.map{|s| Date.strptime(s[:date], "%Y-%m-%d")}.sort!.reverse.map! { |d| d.iso8601 }
    }
  }
end

def work(input: "data.txt")
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

  data = {}
  _tmp_hash = {}
  report = {
    totalUsers: 0,
    uniqueBrowsersCount: 0,
    totalSessions: 0,
    allBrowsers: [],
    usersStats: {}
  }

  File.open(input) do |f|
    f.each_line do |line|
      cols = line.split(',')
      key = cols[1]
      if cols[0] == "user"
        if data[key].nil?
          report[:usersStats].merge!(aggregate_user_stats(data.shift))
        end
        data[key] ||= {}
        data[key][:user] = parse_user(cols)
        report[:totalUsers] += 1
      else
        data[key] ||= {}
        data[key][:sessions] ||= []
        session = parse_session(cols)
        browser = session[:browser]
        if _tmp_hash[browser].nil?
          _tmp_hash[browser] = 1
          report[:allBrowsers].push(browser)
          report[:uniqueBrowsersCount] += 1
        end
        report[:totalSessions] += 1
        data[key][:sessions].push(session)
      end
    end
    report[:usersStats].merge!(aggregate_user_stats(data.shift))
    report[:allBrowsers] = report[:allBrowsers].sort!.join(',')
  end

  File.open('result.json', 'w+') { |f| f.puts report.to_json }
end
