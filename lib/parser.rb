# Deoptimized version of homework task

require 'json'
require 'pry-byebug'
require 'set'
require 'csv'

$support_dir = File.expand_path('../../spec/support', __FILE__ )
$optimizations_dir = File.expand_path('../../optimizations', __FILE__ )

SESSIONS = "\"sessionsCount\":\""
TOTAL_TIME = "\"totalTime\":\""
LONGEST_SESSION = "\"longestSession\":\""
BROWSERS = "\"browsers\":\""
USED_IE = "\"usedIE\":\""
ALWAYS_CHROME = "\"alwaysUsedChrome\":\""
DATES = "\"dates\":\""

def work(filename)
  File.write(
    "#{$support_dir}/result.json",
    "{\"totalUsers\":%{totalUsers},"\
    "\"uniqueBrowsersCount\":%{uniqueBrowsersCount},"\
    "\"totalSessions\":%{totalSessions},"\
    "\"allBrowsers\":\"%{allBrowsers},"\
    "\"usersStats\":{"
  )

  longest_session = total_time = sessions_count = 0
  always_chrome = used_ie = false

  uniqueBrowsers = []
  dates = []
  browsers = []

File.open("#{$support_dir}/result.json", 'a') do |f|
  CSV.foreach("#{$support_dir}/#{filename}", row_sep: "\n") do |row|
    if row[0] == 'user'
      # report[:totalUsers] += 1

      if sessions_count > 0
        user = "\"#{row[2]} #{row[3]}\":{" << SESSIONS << sessions_count.to_s << "\"," <<
            TOTAL_TIME << total_time.to_s << " min.\"," << LONGEST_SESSION << longest_session.to_s << " min.\"," <<
            BROWSERS << browsers.sort!.join(', ').upcase! << "\"," << USED_IE << "#{used_ie}" << "\"," << ALWAYS_CHROME << "#{always_chrome}" <<
            "\"," << DATES << dates.to_s << '},'

        f.write(user)

        longest_session = total_time = sessions_count = 0
        uniqueBrowsers.clear
        dates.clear
        browsers.clear
        always_chrome = used_ie = false
      end
    else
      # report['allBrowsers'] << row[3] << EMPTY_COMMA
      # report['totalSessions'] += 1
      uniqueBrowsers << row[3]

      sessions_count += 1
      total_time += row[4].to_i
      longest_session = row[4].to_i if longest_session < row[4].to_i
      browsers << row[3]
      used_ie = true if used_ie || row[3].start_with?('INTERNET')
      always_chrome = false if used_ie || !always_chrome || !row[3].start_with?('CHROME')
      dates << row[5]
    end
  end

  # report['usersStats'].each_key { |name| report['usersStats'][name]['totalTime'] = report['usersStats'][name]['totalTime'].to_s + ' min.' }
  # report['allBrowsers'].upcase!
  # report['uniqueBrowsersCount'] = uniqueBrowsers.count
  #
  # File.write("#{$support_dir}/result.json", report.to_json << "\n")
end

end
