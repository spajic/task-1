# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'ruby-prof'
require 'benchmark'

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
    'age' => user[4],
  }
end

def parse_session(session)
  {
    'user_id' => session[1],
    'session_id' => session[2],
    'browser' => session[3],
    'time' => session[4],
    'date' => session[5],
  }
end

def work(file = 'data_large.txt')
  return false unless file
  file_lines = File.read(file).split("\n")

  users = []
  sessions_by_id = {}
  sessions_browsers = []

  file_lines.each_slice(10000) do |line_slice|
    line_slice.each do |line|
      cols = line.split(',')
      users << parse_user(cols) if cols[0] == 'user'
      if cols[0] == 'session'
        sessions_browsers << cols[3]
        sessions_by_id[cols[1]] ||= {}
        sessions_by_id[cols[1]]['sessions'] ||= []
        sessions_by_id[cols[1]]['sessions'] << parse_session(cols)
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

  report = {}

  report[:totalUsers] = users.count

  # Подсчёт количества уникальных браузеров
  report['uniqueBrowsersCount'] = sessions_browsers.uniq.count

  report['totalSessions'] = sessions_browsers.count

  report['allBrowsers'] =
    sessions_browsers
      .map { |b| b.upcase }
      .sort
      .uniq
      .join(',')

  # Статистика по пользователям
  users_objects = []

  users.each_slice(500) do |user_slice|
    user_slice.each do |user|
      attributes = user
      user_sessions = sessions_by_id[user['id']]['sessions']
      user_object = User.new(attributes: attributes, sessions: user_sessions)
      users_objects << user_object
    end
  end

  report['usersStats'] = {}

  users_objects.each_slice(500) do |user_slice|
    user_slice.each do |user|
      array_time = user.sessions.map { |s| s['time'].to_i }
      array_browser = user.sessions.map { |s| s['browser'] }
      user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
      report['usersStats'][user_key] ||= {}
      report['usersStats'][user_key]['sessionsCount'] = user.sessions.count
      report['usersStats'][user_key]['totalTime'] = array_time.sum.to_s + ' min.'
      report['usersStats'][user_key]['longestSession'] = array_time.max.to_s + ' min.'
      report['usersStats'][user_key]['browsers'] = array_browser.map { |b| b.upcase}.sort.join(', ')
      report['usersStats'][user_key]['usedIE'] = array_browser.map { |b| b.upcase =~ /INTERNET EXPLORER/ }.include? 0
      report['usersStats'][user_key]['alwaysUsedChrome'] = user.sessions.map{|s| s['browser']}.all? { |b| b.upcase =~ /CHROME/ }
      report['usersStats'][user_key]['dates'] = user.sessions.map{|s| s['date'] }.sort.reverse
    end
  end
  File.write('result.json', "#{report.to_json}\n")
end
