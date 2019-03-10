# Deoptimized version of homework task
  
# Stackprof ObjectAllocations and Flamegraph
# stackprof tmp/stackprof.dump --text --limit 3
# stackprof tmp/stackprof.dump --method 'Object#make_csv_of_data'
#
# Flamegraph
# raw: true
# stackprof --flamegraph tmp/stackprof.dump > tmp/flamegraph
# stackprof --flamegraph-viewer=tmp/flamegraph
#
# dot -Tpng graphviz.dot > graphviz.png

require 'stackprof'
require 'json'
require 'date'
require 'benchmark'
require 'byebug'
require 'gc_tracer'
require 'memory_profiler'
require 'ruby-prof'
require 'get_process_mem'

# RubyProf.measure_mode = RubyProf::ALLOCATIONS

class User
  attr_reader :attributes, :sessions, :user_key

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
    @user_key = attributes[:full_name]
  end
end

class Parser
  attr_accessor :user
  def initialize
    @user = nil
  end
  def parse_user(fields)
    # byebug
    parsed_result = {
      id: fields[1],
      full_name: fields[2] + ' ' + fields[3],
      age: fields[4],
    }
  end

  def parse_session(fields)
    # byebug
    parsed_result = {
      user_id: fields[1],
      session_id: fields[2],
      browser: fields[3],
      time: fields[4],
      date: fields[5],
    }
  end

  def collect_stats_from_users(report, users_objects)
    report_result_per_user = {
      sessionsCount: 0,
      totalTime: 0,
      longestSession: 0,
      browsers: [],
      usedIE: false,
      alwaysUsedChrome: false,
      dates: [    
      ]

    }
    users_objects.each do |user|
      
      report[:usersStats][user.user_key] ||= {}
      report_result_per_user[:sessionsCount] = user.sessions.count 
      report_result_per_user[:totalTime] = user.sessions.map{|s| s[:time].to_i}.sum.to_s << ' min.'
      report_result_per_user[:longestSession] = user.sessions.map {|s| s[:time]}.map {|t| t.to_i}.max.to_s + ' min.'
      report_result_per_user[:browsers] = user.sessions.map {|s| s[:browser]}.map {|b| b.upcase}.sort.join(', ')
      report_result_per_user[:usedIE] = user.sessions.map{|s| s[:browser]}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ }
      report_result_per_user[:alwaysUsedChrome] = user.sessions.map{|s| s[:browser]}.all? { |b| b.upcase =~ /CHROME/ }
      report_result_per_user[:dates] = user.sessions.sort_by!{ |s| s[:date] }.reverse!.map{ |s| Date.iso8601(s[:date]) } 
      report[:usersStats][user.user_key] = report[:usersStats][user.user_key].merge!(report_result_per_user)
      # byebug
    end
  end

  def work(file)
    # puts  "rss before iteration: #{print_memory_usage}"
    # report_mem_prof = MemoryProfiler.report do
    # old_stat = GC.stat
    # puts "old_stat: #{old_stat}"
  
    # GC::Profiler.enable
    # GC::Tracer.start_logging('gc_tracer.csv') do
    # result = RubyProf.profile do
    # StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
    time = Benchmark.realtime do
      users = []
      user_sessions = []
      total_sessions = 0
      sessions = {}
      unique_browsers = []
      File.open(file, 'r').each do |f|
        f.each_line do |line|
          cols = line.split(',')
      
          if cols[0] == 'user'
            self.user = parse_user(cols)
            users << user
          end
          # byebug
          if cols[0] == 'session'
            session = parse_session(cols)
            sessions[user[:id]] ||= []
            sessions[user[:id]] << session if session[:user_id] == user[:id]
            total_sessions += 1 
            browser = session[:browser].upcase!
            unique_browsers << browser unless unique_browsers.include?(browser)
          end
        end
      end

      # byebug

      # raise StandardError, 'There is too much stuff'

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

      report[:uniqueBrowsersCount] = unique_browsers.count

      report[:totalSessions] = total_sessions

      report[:allBrowsers] =
        unique_browsers
          .sort
          .join(',')

      report[:usersStats] = {}

      # Статистика по пользователям
      users_objects = []
      
      users.each do |user|
        user_sessions = sessions[user[:id]]
        # byebug
        users_objects << User.new(attributes: user, sessions: user_sessions)
      end
        

      collect_stats_from_users(report, users_objects)
      # byebug


      File.write('result.json', "#{report.to_json}\n")
      # mem = GetProcessMem.new
      # puts mem.inspect

    end

    puts "Finish in #{time.round(2)}"
    # end
    # report_mem_prof.pretty_print(scale_bytes: true)
    #  puts  "rss after iteration: #{print_memory_usage}"

    # end
  
    # StackProf::Report.new(profile_data).print_text
    # StackProf::Report.new(profile_data).print_method(/work/)
    # StackProf::Report.new(profile_data).print_graphviz
    # end

    # printer = RubyProf::FlatPrinter.new(result)
    # printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

    # printer = RubyProf::DotPrinter.new(result)
    # printer.print(File.open("ruby_prof_allocations_profile_4.dot", "w+"))

    # printer = RubyProf::GraphHtmlPrinter.new(result)
    # printer.print(File.open("ruby_prof_graph_allocations_profile_4.html", "w+"))

    
    # end
    # GC::Profiler.report
    # GC::Profiler.disable
    
    # new_stat = GC.stat
    # puts "new_stat: #{new_stat}"
  
  end

  private

  #amount of RAM, allocated for the process currently
  def print_memory_usage
    "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
  end
end
