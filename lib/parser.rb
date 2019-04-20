# frozen_string_literal: true
# Deoptimized version of homework task

require 'json'
require 'set'
require 'oj'

$support_dir = File.expand_path('../../spec/support', __FILE__ )
$optimizations_dir = File.expand_path('../../optimizations', __FILE__ )

def work(filename)
  report_general_str = "\"totalUsers\":%{totalUsers},"\
    "\"uniqueBrowsersCount\":%{uniqueBrowsersCount},"\
    "\"totalSessions\":%{totalSessions},"\
    "\"allBrowsers\":\"%{allBrowsers}\"}}\n"\

  report_general = {}
  report_general[:totalUsers] = report_general[:totalSessions] = 0
  report_general[:uniqueBrowsersCount] = Set.new

  user_name = ''
  user_longest_session = user_total_time = user_sessions_count = 0
  user_always_chrome = user_used_ie = false
  user_dates = []
  user_browsers = []

  File.open("#{$support_dir}/result.json", 'w') do |f|
    f.write("{\"usersStats\":{")

    IO.foreach("#{$support_dir}/#{filename}") do |cols|
      row = cols.split(',')

      if cols.start_with?('user')
        if user_sessions_count > 0
          user_dates.sort!.reverse!

          browsers = user_browsers.sort!.join(', ').upcase!
          user_always_chrome = true if browsers.end_with?('CHROME')
          user_used_ie = true if !user_always_chrome && browsers.include?('INTERNET')

          user_report = {
            "sessionsCount": user_sessions_count,
            "totalTime": "#{user_total_time} min.",
            "longestSession": "#{user_longest_session} min.",
            "browsers": browsers,
            "usedIE": user_used_ie,
            "alwaysUsedChrome": user_always_chrome,
            "dates": user_dates
          }

          f.write("\"#{user_name}\":#{Oj.dump(user_report, mode: :compat)},")

          report_general[:totalSessions] += user_sessions_count
          report_general[:totalUsers] += 1

          user_longest_session = user_total_time = user_sessions_count = 0
          user_dates.clear
          user_browsers.clear

          user_always_chrome = user_used_ie = false
        end

        user_name = "#{row[2]} #{row[3]}"
      else
        user_sessions_count += 1

        user_total_time += row[4].to_i
        user_longest_session = row[4].to_i if user_longest_session < row[4].to_i
        user_browsers << row[3]
        report_general[:uniqueBrowsersCount] << row[3]

        user_dates << row[5].strip
      end
    end

    user_dates.sort!.reverse!

    browsers = user_browsers.sort!.join(', ').upcase!
    user_always_chrome = true if browsers.end_with?('CHROME')
    user_used_ie = true if !user_always_chrome && browsers.include?('INTERNET')

    user_report = {
      "sessionsCount": user_sessions_count,
      "totalTime": "#{user_total_time} min.",
      "longestSession": "#{user_longest_session} min.",
      "browsers": browsers,
      "usedIE": user_used_ie,
      "alwaysUsedChrome": user_always_chrome,
      "dates": user_dates
    }

    f.write("\"#{user_name}\":#{Oj.dump(user_report, mode: :compat)},")

    report_general[:totalSessions] += user_sessions_count
    report_general[:totalUsers] += 1

    report_general[:allBrowsers] = report_general[:uniqueBrowsersCount].sort.join(',').upcase!
    report_general[:uniqueBrowsersCount] = report_general[:uniqueBrowsersCount].size

    f.write(report_general_str % report_general)
  end
end
