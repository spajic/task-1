# Optimisation case-study

## Actual problem
Our project started performing poorly.

We had to process a file slightly larger then 100mb.

We already had a ruby program that was doing the job, but unfortunately it didn't scale well. At some point it started working so slow that we where not sure wether it's going to finish processing in some reasonable time.

So I grabbed my optimisation hat.

## Establishing metrics
To measure the impact changes are having on our program I needed some reliable metrics. So first I created few sample files for 10, 100, 1k, 10k, 20k, and 30k lines each.First I measured iterations per second usign (with [benchmark-ips](https://github.com/evanphx/benchmark-ips) gem) each file as argument for main method. I turned out that 30k performed 76062 times slower then 10 lines in context of ips. But benchmark-ips can't do wall time so had to reach out for benchmark from ruby standard library. It apreas that it takes 4 seconds to process 10k, and 59,5 seconds to process. Life is too short to wait a minute each time so I stoped on 20k lines which would perform in 26 seconds and where 36876 times slower then 10 lines in terms of ips. I can work with that. So now we have our _base case: 20k lines performing in 26 seconds_

## Prevent regression
To make sure I don't accidentally introduce regression, during each iteration I was running test suit that was in place. Also had to add performance tests to make sure I don't introduce regression in performance.

## Feedback Loop
I've picked tools that are going to help me in my bottleneck quest. Which where
`stack_prof`
`ruby_prof`
`memory_profiler`
`benchmark`
`benchmark-ips`
And measuring memory from system proces like this:
```
#   "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
```

To run experiments fast I've commited to the following feedback loop:

1. Measure portion of code using one of the tools above.
2. Introduce changes in production code.
3. Run tests.
4. Measure same aspect of code using same tool as in N1.
5. Measure against base metics case.
6. Write performance test / rollback.
7. Go to step one.

## Deep dive into system to find 20% growth points.
Using the feedback loop above I was able to detect and solve following:

### Discovery 1
Using StackProf I've noticed that this block of code allocates 413908 objects.

```ruby
file_lines.each do |line|
  cols = line.split(',')
  users = users + [parse_user(line)] if cols[0] == 'user'
  sessions = sessions + [parse_session(line)] if cols[0] == 'session'
end
```
First thing I've extracted string literals into constant and froze them. Also added magic frozen string literal comment at start of the file. (Only this reduced allocation by 80k objects and speeded up base metrics to 22,7 seconds). Then avoided creating extra arrays and edited original arrays in place (what reduced allocation on 4k more).

```
users << parse_user(line) if cols[0] == USER_STR
sessions << parse_session(line) if cols[0] == SESSION_STR
```
Now program performed in 18.63 seconds what is 10 seconds faster then base metrics.


### Discovery 2
While still here I decided to swap `Array#split` to `String#start_with?` which is according to [fast ruby](https://github.com/JuanitoFatas/fast-ruby) faster.
```
  file_lines.each do |line|
    users << parse_user(line) if line.start_with?(USER_STR)
    sessions << parse_session(line) if line.start_with?(SESSION_STR)
  end
```

Now program performed in 14-16 seconds range.

### Discovery 3
After those changes I moved on to `collect_stats_from_users` method which according to StackProf was the baddest guy in town atm. Kick started with date parsing line where 594436 objects where allocated. Last map was clearly unnecessary so I parsed date in first map. What reduced allocation more then 2 times.
```
{ 'dates' => user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 } }
```
Then using Date.strptime instead of iso8061 format improved object allocation.

from 246194 (48.6%) / 127512 (25.2%) | 134 |
to   107524 (25.0%) / 56654 (13.2%) | 112 |
What is 6 times less then what we started with. But unfortunately that didn't imporove our base speed metrics.

### Discovery 4
Next I made a series of actions that reduced object allocation in several places.

Grouped first and last name to just name, as they where not used separately.
```
def parse_user(user)
    ...
    'name' => "#{fields[2]} #{fields[3]}",
    ...
def collect_stats_from_users(report, users_objects, &block)
  ...
    user_key = user.attributes['full_name']
    ...
```
This removed 15k object allocations.


Extracted user and session counts to a counter hash and increased value when `parse_user/session` where invoked.

```
  ...
  report = {
    totalUsers: 0,
    uniqueBrowsersCount: 0,
    totalSessions: 0,
  }
  users = []
  sessions = []

  File.foreach(filename) do |line|
    if line.start_with?(USER_STR)
      users << parse_user(line)
      report[:totalUsers] += 1
  ...
```

Removed extra array here by editing original in place
```
users_objects = users_objects + [user_object]
# after
users_objects << user_object
```
What saved 6k objects

Noticed that in all browser related operations there is an extra cycle where browser name is upcased. As we did not need browser name in lower register I've upcased it in place when original hash with sessions was saved.
```
  parsed_result = {
    user_id: fields[1],
    session_id: fields[2],
    browser: fields[3].upcase!,
    ...
```
What reduced object allocation in method `work` by 33k more.

Did few more changes like this. But they didn't affect my base speed test what was really dissapointing. I've decided to move on to other tool.

### Discovery 5

I ran program through memory_profiler gem and was shoked. Innocent `Array#select` nested in `Array#each` was causing a lot of trouble.

```
  users.each do |user|
    attributes = user
:82 >    user_sessions = sessions.select { |session| session[:user_id] == user[:id] }
    users_objects << User.new(attributes: attributes, sessions: user_sessions)
end
```

Old stats
```
allocated memory by location
-----------------------------------
 413256912  task-1.rb:82 <- Look at that number
   7459760  task-1.rb:31
   5973007  task-1.rb:110
   5942016  task-1.rb:103
```

Grouping session by user_id did the trick.
```
  users_objects = []
  sessions_by_user = sessions.group_by { |s| s[:user_id] }

  users.each do |user|
    attributes = user
    user_sessions = sessions_by_user[user[:id]] || []
    users_objects << User.new(attributes: attributes, sessions: user_sessions)
  end
```
Improved stats
```
allocated memory by location
-----------------------------------
   7459760  task-1.rb:31
   5973007  task-1.rb:113
   5942016  task-1.rb:106
   3933328  task-1.rb:32
```

So resident set size was reduced from 336MB to
```
rss before: 23 MB
rss after: 45 MB
```

And __base metrics was improved from 13-14 seconds to 0.54-0.58 seconds__. And I finally was able to process large 132MB data file in 62 seconds. Which could be considered as success already and we could stop there. But I wanted to get bellow 50 seconds so back to discoveries.

### Discovery 6

Next step. I've noticed that all sessions are collected few times to only work with browsers. And in report we need only uniq browsers count, but not their list. So while sessions where processed, in parallel collected all browsers in array and worked with them afterwards.

```
  # uniqueBrowsers = []
  # sessions.each do |session|
  #   browser = session[:browser]
  #   uniqueBrowsers += [browser] if uniqueBrowsers.all? { |b| b != browser }
  # end

  report[:uniqueBrowsersCount] = all_browsers.uniq.size
```

This reduced allocated memory on 1MB more but more imporantly it made me see that I needed only uniq browsers so I could change order operations so sorting was happening on uniq array (with less elements then original) and was modifying original array in place.
```
# before
  report[:allBrowsers] = 
    # getting browser from sessions here
    .sort
    .uniq
    .join(',')

  report[:uniqueBrowsersCount] = all_browsers.uniq.size
# after

  report[:allBrowsers] = all_browsers
    .uniq!
    .sort!
    .join(',')

  report[:uniqueBrowsersCount] = all_browsers.size
```
This improved statics of invoking `Array#all?`
from
 0.002      0.002      0.000      0.000        3046/20000     Array#all?
to
 0.002      0.002      0.000      0.000        3046/3046     Array#all?

 what is ~17k calls less.

 So now the large file was processed for 48-50 seconds. What is 12-14 seconds less then after last imporvement. And that reduced allocated memory to 2340MB what is 68MB less then last test.


### Discovery 7

Did few more optimisations but they didn't produce significant improvements. Until by using memory profiler I've noticed that new line character is allocated 16k times when date is parsed in line 103.
```ruby
      'dates' => u.sessions.map! { |s| Date.strptime(s[:date], DATE_PATTERN) }.sort! {|a,b| b <=> a}
```
I guessed that it could be only in date from hash.

```

allocated objects by class
-----------------------------------
    259730  String
    
Allocated String Report
-----------------------------------
     16954  "\n"
     16954  task-1.rb:103
     
allocated objects by location
-----------------------------------
    118678  task-1.rb:31
     90477  task-1.rb:110
     53608  task-1.rb:103
     
allocated memory by class
-----------------------------------
   13.4 MB  String

allocated memory by location
-----------------------------------
   7.46 MB  task-1.rb:31
   5.97 MB  task-1.rb:110
   5.94 MB  task-1.rb:103
```
So I cut new line char with `String#chomp!`. Used bang version so copy is not saved. And I was right. New line char was not on the chart anymore.

```

allocated objects by class
-----------------------------------
    242776  String
    
Allocated String Report
-----------------------------------
     16954  "session"
     16954  task-1.rb:31

      3200  "0"
      
allocated objects by location
-----------------------------------
    118678  task-1.rb:31
     90477  task-1.rb:110
     36654  task-1.rb:103

allocated memory by class
-----------------------------------
  12.72 MB  String

allocated memory by location
-----------------------------------
   7.46 MB  task-1.rb:31
   5.97 MB  task-1.rb:110
   5.26 MB  task-1.rb:103
```

Then I used a trick I found in Ruby Performance Optimisation which I was reading in breaks between the optimisations and got rid of date parsings completely.

```
Date.civil(s[:date][0,4].to_i, s[:date][5,2].to_i, s[:date][8,2].to_i)
```
This trick imporved memory consumption on big file and improved speed performance to 42-44 seconds.

```
rss before: 23 MB
rss after: 2285 MB
 ~/sites/rubyperf/task-1   optimisation ●  ruby task-1.rb
Rehearsal --------------------------------------------
Big file  41.666922   1.193757  42.860679 ( 42.996395)
---------------------------------- total: 42.860679sec

               user     system      total        real
Big file  41.682918   3.014357  44.697275 ( 44.852391)
```

### Discovery 8

Then using ruby-prof I've noticed that method `String#start_with?` is invoked 40ktimes in a block where program spends `34.71%` of all time. I assumend that there is going to be more sessions than users and swaped checks with places and if line was starting with session I moved on to the next iteration without checking if line is starting with user string.

```
loop
    if line.start_with?(SESSION_PREFIX)
      sessions << parse_session(line)
      next if report[:totalSessions] += 1
    end

    if line.start_with?(USER_PREFIX)

```
This imporved allocation to `23046/23046  String#start_with?` and in this block since was spent `30.46%` of all time. And now large file is consuming `rss after: 2254 MB`of memory.


## Conclusion
So as a result of our optimisation we where able to read file that wasn't readable (in terms of time) in 39-47 seconds. And inporove memory allocation to 2254 MB. To measure we uses 20k lines sample wich took almost 29 seconds to run. Now it runs in 0.25 seconds. That means that our program is now __116 times faster___.

## Regression prevention

To protect ourselfs from regression we've added performance tests.
