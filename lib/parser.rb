# Deoptimized version of homework task

require 'json'
require 'pry-byebug'
require 'csv'

$support_dir = File.expand_path('../../spec/support', __FILE__ )
$optimizations_dir = File.expand_path('../../optimizations', __FILE__ )

SESSIONS = "\"sessionsCount\":"
TOTAL_TIME = "\"totalTime\":\""
LONGEST_SESSION = "\"longestSession\":\""
BROWSERS = "\"browsers\":\""
USED_IE = "\"usedIE\":"
ALWAYS_CHROME = "\"alwaysUsedChrome\":"
DATES = "\"dates\":["

def work(filename)
  report_general_str = "\"totalUsers\":%{totalUsers},"\
    "\"uniqueBrowsersCount\":%{uniqueBrowsersCount},"\
    "\"totalSessions\":%{totalSessions},"\
    "\"allBrowsers\":\"%{allBrowsers}\"}}\n"\

  report_general = {}
  report_general[:totalUsers] = report_general[:totalSessions] = 0
  report_general[:uniqueBrowsersCount] = []

  user_name = ''
  user_longest_session = user_total_time = user_sessions_count = 0
  user_always_chrome = user_used_ie = false
  user_dates = []
  user_browsers = []

  File.open("#{$support_dir}/result.json", 'w') do |f|
    f.write("{\"usersStats\":{")

    CSV.foreach("#{$support_dir}/#{filename}", row_sep: "\n") do |row|
      if row[0] == 'user'
        if user_sessions_count > 0
          user_dates.sort!.reverse!

          browsers = user_browsers.sort!.join(', ').upcase!
          user_always_chrome = true if browsers.end_with?('CHROME')
          user_used_ie = true if !user_always_chrome && browsers.match?('INTERNET')

          user = "\"#{user_name}\":{" << SESSIONS << user_sessions_count.to_s << "," <<
              TOTAL_TIME << user_total_time.to_s << " min.\"," << LONGEST_SESSION << user_longest_session.to_s << " min.\"," <<
              BROWSERS << browsers << "\"," << USED_IE << "#{user_used_ie}" << "," << ALWAYS_CHROME << "#{user_always_chrome}" <<
              "," << DATES

          while date = user_dates.shift
            user_dates.size == 0 ? user << "\"#{date}\"]}," : user << "\"#{date}\","
          end

          f.write(user)

          report_general[:uniqueBrowsersCount].concat user_browsers
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

        user_dates << row[5]
      end
    end

    user_dates.sort!.reverse!

    browsers = user_browsers.sort!.join(', ').upcase!
    user_always_chrome = true if browsers.end_with?('CHROME')
    user_used_ie = true if !user_always_chrome && browsers.match?('INTERNET')

    user = "\"#{user_name}\":{" << SESSIONS << user_sessions_count.to_s << "," <<
        TOTAL_TIME << user_total_time.to_s << " min.\"," << LONGEST_SESSION << user_longest_session.to_s << " min.\"," <<
        BROWSERS << browsers << "\"," << USED_IE << "#{user_used_ie}" << "," << ALWAYS_CHROME << "#{user_always_chrome}" <<
        "," << DATES

    while date = user_dates.shift
      user_dates.size == 0 ? user << "\"#{date}\"]}," : user << "\"#{date}\","
    end

    report_general[:uniqueBrowsersCount].concat user_browsers
    report_general[:totalSessions] += user_sessions_count
    report_general[:totalUsers] += 1

    f.write(user)

    report_general[:uniqueBrowsersCount].sort!.uniq!
    report_general[:allBrowsers] = report_general[:uniqueBrowsersCount].join(',').upcase!
    report_general[:uniqueBrowsersCount] = report_general[:uniqueBrowsersCount].size

    f.write(report_general_str % report_general)
  end
end
