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
    @user_key = "#{attributes['first_name']}" + ' ' + "#{attributes['last_name']}"
  end
end

class Parser
  attr_accessor :user
  def initialize
    @user = nil
  end
  def parse_user(fields)
    parsed_result = {
      'id' => fields[1],
      'first_name' => fields[2],
      'last_name' => fields[3],
      'age' => fields[4],
    }
  end

  def parse_session(fields)
    parsed_result = {
      'user_id' => fields[1],
      'session_id' => fields[2],
      'browser' => fields[3],
      'time' => fields[4],
      'date' => fields[5],
    }
  end

  def collect_stats_from_users(report, users_objects, &block)
    # report_result_per_user = {
    #   sessionsCount: 0,
    #   totalTime: 0,
    #   longestSession: 0,
    #   browsers: [],
    #   usedIE: false,
    #   alwaysUsedChrome: false,
    #   dates: [    
    #   ]

    # }
    users_objects.each do |user|
      # report_result_per_user[:dates] = user.sessions.sort_by{ |s| Date.iso8601(s['date']) }.reverse
        
      report['usersStats'][user.user_key] ||= {}
      report['usersStats'][user.user_key] = report['usersStats'][user.user_key].merge(block.call(user))
    end
  end

  def work(file)
    # puts  "rss before iteration: #{print_memory_usage}"
    # report_mem_prof = MemoryProfiler.report do
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
            sessions[user['id']] ||= []
            sessions[user['id']] << session if session['user_id'] == user['id']
            total_sessions += 1 
            browser = session['browser'].upcase!
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

      report['uniqueBrowsersCount'] = unique_browsers.count

      report['totalSessions'] = total_sessions

      report['allBrowsers'] =
        unique_browsers
          .sort
          .join(',')

      # Статистика по пользователям
      users_objects = []
      
        # old_stat = GC.stat
        # puts "old_stat: #{old_stat}"
      
        # GC::Profiler.enable
        # GC::Tracer.start_logging('gc_tracer.csv') do
        # result = RubyProf.profile do
        # StackProf.run(mode: :object, out: 'tmp/stackprof.dump', raw: true) do
          users.each do |user|
            user_sessions = sessions[user['id']]
            # byebug
            user_object = User.new(attributes: user, sessions: user_sessions)
            users_objects << user_object
          end
        # end

       
        
        # StackProf::Report.new(profile_data).print_text
        # StackProf::Report.new(profile_data).print_method(/work/)
        # StackProf::Report.new(profile_data).print_graphviz
        # end

        # printer = RubyProf::FlatPrinter.new(result)
        # printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

        # printer = RubyProf::DotPrinter.new(result)
        # printer.print(File.open("ruby_prof_allocations_profile_1.dot", "w+"))

        # printer = RubyProf::GraphHtmlPrinter.new(result)
        # printer.print(File.open("ruby_prof_graph_allocations_profile_1.html", "w+"))

       
        # end
        # GC::Profiler.report
        # GC::Profiler.disable
       
        # new_stat = GC.stat
        # puts "new_stat: #{new_stat}"
      

      report['usersStats'] = {}

      # Собираем количество сессий по пользователям
      collect_stats_from_users(report, users_objects) do |user|
        { 'sessionsCount' => user.sessions.count }
      end

      # Собираем количество времени по пользователям
      collect_stats_from_users(report, users_objects) do |user|
        { 'totalTime' => user.sessions.map {|s| s['time']}.map {|t| t.to_i}.sum.to_s + ' min.' }
      end

      # Выбираем самую длинную сессию пользователя
      collect_stats_from_users(report, users_objects) do |user|
        { 'longestSession' => user.sessions.map {|s| s['time']}.map {|t| t.to_i}.max.to_s + ' min.' }
      end

      # Браузеры пользователя через запятую
      collect_stats_from_users(report, users_objects) do |user|
        { 'browsers' => user.sessions.map {|s| s['browser']}.map {|b| b.upcase}.sort.join(', ') }
      end

      # Хоть раз использовал IE?
      collect_stats_from_users(report, users_objects) do |user|
        { 'usedIE' => user.sessions.map{|s| s['browser']}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ } }
      end

      # Всегда использовал только Chrome?
      collect_stats_from_users(report, users_objects) do |user|
        { 'alwaysUsedChrome' => user.sessions.map{|s| s['browser']}.all? { |b| b.upcase =~ /CHROME/ } }
      end

      # Даты сессий через запятую в обратном порядке в формате iso8601
      collect_stats_from_users(report, users_objects) do |user|
        # byebug
        { 'dates' => user.sessions.sort_by!{ |s| s['date'] }.reverse!.map{ |s| Date.iso8601(s['date']) } }
      end

      File.write('result.json', "#{report.to_json}\n")
      mem = GetProcessMem.new
      puts mem.inspect

    end

    puts "Finish in #{time.round(2)}"
    # end
    # report_mem_prof.pretty_print(scale_bytes: true)
    #  puts  "rss after iteration: #{print_memory_usage}"
  end

  private

  #amount of RAM, allocated for the process currently
  def print_memory_usage
    "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
  end
end
