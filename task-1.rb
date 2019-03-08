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
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

class Parser
  def parse_user(user)
    fields = user.split(',')
    parsed_result = {
      'id' => fields[1],
      'first_name' => fields[2],
      'last_name' => fields[3],
      'age' => fields[4],
    }
  end

  def parse_session(session)
    fields = session.split(',')
    parsed_result = {
      'user_id' => fields[1],
      'session_id' => fields[2],
      'browser' => fields[3],
      'time' => fields[4],
      'date' => fields[5],
    }
  end

  def collect_stats_from_users(report, users_objects, &block)
    users_objects.each do |user|
      user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
      report['usersStats'][user_key] ||= {}
      report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))
    end
  end

  def work(file)
      users = []
      sessions = []
     
      File.open(file, 'r').each do |f|
        f.each_line do |line|
          cols = line.split(',')
          users << parse_user(line) if cols[0] == 'user'
          sessions << parse_session(line) if cols[0] == 'session'
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
      
      # Подсчёт количества уникальных браузеров
      uniqueBrowsers = []
      # it was Finish in 0.21,
      # then Finish in 0.19
      time = Benchmark.realtime do
        sessions.each do |session|
          uniqueBrowsers << session['browser'] if uniqueBrowsers.all? { |b| b != session['browser'] }
        end
      end
      
      puts "Finish in #{time.round(2)}"

      report['uniqueBrowsersCount'] = uniqueBrowsers.count

      report['totalSessions'] = sessions.count

      report['allBrowsers'] =
        sessions
          .map { |s| s['browser'] }
          .map { |b| b.upcase }
          .sort
          .uniq
          .join(',')

      # Статистика по пользователям
      users_objects = []
      time = Benchmark.realtime do
        # old_stat = GC.stat
        # puts "old_stat: #{old_stat}"
        # puts  "rss before iteration: #{print_memory_usage}"
        # GC::Profiler.enable
        # GC::Tracer.start_logging('gc_tracer.csv') do
        # report = MemoryProfiler.report do
        # result = RubyProf.profile do
          users.each do |user|
            user_sessions = sessions.select { |session| session['user_id'] == user['id'] }
            user_object = User.new(attributes: user, sessions: user_sessions)
            users_objects << user_object
          end
        # end

        # printer = RubyProf::FlatPrinter.new(result)
        # printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

        # printer = RubyProf::DotPrinter.new(result)
        # printer.print(File.open("ruby_prof_allocations_profile_1.dot", "w+"))

        # printer = RubyProf::GraphHtmlPrinter.new(result)
        # printer.print(File.open("ruby_prof_graph_allocations_profile_1.html", "w+"))

        # end
        # report.pretty_print(scale_bytes: true)
        # end
        # GC::Profiler.report
        # GC::Profiler.disable
        # puts  "rss after iteration: #{print_memory_usage}"
        # new_stat = GC.stat
        # puts "new_stat: #{new_stat}"
      end

      puts "Finish in #{time.round(2)}"

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
        { 'dates' => user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 } }
      end

      File.write('result.json', "#{report.to_json}\n")
      mem = GetProcessMem.new
      puts mem.inspect
    
    end

    private

    #amount of RAM, allocated for the process currently
    def print_memory_usage
      "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
    end
end
