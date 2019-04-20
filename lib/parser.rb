# Deoptimized version of homework task

require 'json'
require 'set'
require 'oj'
require 'forwardable'
require 'pry-byebug'

$support_dir = File.expand_path('../../spec/support', __FILE__ )
$optimizations_dir = File.expand_path('../../optimizations', __FILE__ )

class User
  attr_accessor :name, :sessions_count, :total_time, :longest_session,
    :browsers, :dates, :used_ie, :used_only_chrome

  def initialize
    nullify

    @dates = []
    @browsers = []
  end

  def prepare
    @dates.sort!.reverse!

    browsers = @browsers.sort!.join(', ').upcase!

    @used_only_chrome = true if browsers.end_with?('CHROME')
    @used_ie = true if !@used_only_chrome && browsers.include?('INTERNET')

    browsers
  end

  def reset
    nullify

    @dates.clear
    @browsers.clear
  end

  private
  def nullify
    @longest_session = @total_time = @sessions_count = 0
    @used_only_chrome = @used_ie = false
  end
end

class Parser
  @parsed_user = User.new

  class << self
    extend Forwardable

    attr_reader :parsed_user

    def parse_user(first_name, last_name)
      @parsed_user.name = "#{first_name} #{last_name}"
    end

    def parse_session(browser, time, date)
      @parsed_user.sessions_count += 1

      @parsed_user.total_time += time
      @parsed_user.longest_session = time if @parsed_user.longest_session < time
      @parsed_user.browsers << browser
      Report.unique_browsers << browser

      @parsed_user.dates << date
    end

    private
    def_delegator :@parsed_user, :name, :parsed_exists?
    def_delegator :@parsed_user, :reset, :clear_cache
  end
end

class Report
  class << self
    attr_reader :unique_browsers, :total_sessions, :total_users

    def prepare(file)
      @file = file
      @unique_browsers = Set.new
      @total_sessions = @total_users = 0

      @file.write("{\"usersStats\":{")
    end

    def add_parsed(user)
      browsers = user.prepare

      @total_sessions += user.sessions_count
      @total_users += 1

      formatted = {
        "sessionsCount": user.sessions_count,
        "totalTime": "#{user.total_time} min.",
        "longestSession": "#{user.longest_session} min.",
        "browsers": browsers,
        "usedIE": user.used_ie,
        "alwaysUsedChrome": user.used_only_chrome,
        "dates": user.dates
      }

      @file.write("\"#{user.name}\":#{Oj.dump(formatted, mode: :compat)},")
    end

    def add_analyse
      analyze = {
        "totalUsers": @total_users,
        "uniqueBrowsersCount": @unique_browsers.size,
        "totalSessions": @total_sessions,
        "allBrowsers": @unique_browsers.sort.join(',').upcase!
      }.to_json.tr!('{', '') << "}\n"

      @file.write(analyze)
    end
  end
end

def work(filename)
  File.open("#{$support_dir}/result.json", 'w') do |f|
    Report.prepare(f)

    IO.foreach("#{$support_dir}/#{filename}") do |cols|
      row = cols.split(',')

      if cols.start_with?('user')
        if Parser.parsed_exists?
          Report.add_parsed(Parser.parsed_user)

          Parser.clear_cache
        end

        Parser.parse_user(row[2], row[3])
      else
        Parser.parse_session(row[3], row[4].to_i, row[5].strip)
      end
    end

    Report.add_parsed(Parser.parsed_user)

    Report.add_analyse
  end
end
