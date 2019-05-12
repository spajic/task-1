Show less
5000/5000
Character limit: 5000
# Case-study optimization

## Actual problem
Our project has a serious problem.

It was necessary to process the data file, a little more than one hundred twenty megabytes (3 million lines).

We already had a program on `ruby` that knew how to do the necessary processing.

It worked successfully on files with a size of a couple of megabytes , but for a large file it worked too long, and it wasn’t clear if it would finish the job at all in some reasonable time.

I decided to fix this problem by optimizing this program.

## Metric formation


At first I wanted to test the program with a large file, but after 10 minutes of waiting for it to end and it didn't look like it was going to finish any time soon and decided to do the optimization with a smaller file.

In order to find a more or less normal number of lines, where file processing is not very time consuming I used benchmark.realtime.
I reduced the file to 98_000 lines, but this didn’t help me much, since the file processing was still too long for me.
As a result, I reduced the number of lines to 30_450, which was equivalent to 1.1 MB.
After that file processing time was 50.04 seconds. This value became the start metric for me.

At first, I decided to check all the metrics from the lecture in order to have some practice using them.
In the process of optimization, I formed metrics using:
1. Memory Gem set
2. MemoryProfiler
3. Ruby Prof
4. StackProf



## Guaranteed correct operation of an optimized program
The program was delivered with the test.
Running this test will prevent changes to the program logic during optimization.
The test was later rewritten in RSpec format.

## Feedback-Loop
In order to be able to quickly test hypotheses, I built an effective feedback loop,
which allowed me to get feedback on the effectiveness of the changes made.

Here's how I built feedback_loop: * how you built feedback_loop *
1. Make a code change
2. Check if the change passes in the code
3. If the test passes, check if the metrics have metrics
4. If the test does not read, see item 1.
5. If metrics are acceptable, push to GitHub

## We delve into the details of the system to find 20% of growth points
In order to find "growth points" for optimization, I used the following tools:
1. Benchmark.realtime
2. MemoryProfiler
3. Ruby Prof

Here are the problems that were found and solved.

### Your Find # 1
About your find # 1
It's hard to refrain from refactoring code right away.

### Your Find # 2
Several problematic areas were found for users `users.each` and sessions ` sessions.each`
As practice has shown, it is better to avoid using the concatenation character in `users_objects = users_objects + [user_object]` and use `<<` instead. Thus, we can avoid creating additional objects in memory. I also tried to avoid assigning values ​​to additional variables when it was possible, so that reading the program still made sense.

At first I decided to deal with the code for iterating users in line 128.
I also changed the code for session iterations from `UniqueBrowsers + = [browser]` to `uniqueBrowsers << session ['browser']`. Thus, we could reduce the number of additional objects created earlier.
After changing the code to use `<<` and removing additional variables, I was able to reduce the processing time of a 1 MB file from 50 to 38.44 seconds.
### Your Find 3
I also noticed using MemoryProfiler that many objects were created in this line of code.

`` `
report ['allBrowsers'] =
  sessions
    .map {| s | s ['browser']}
    .map {| b | b.upcase}
    .sort
    .uniq
    .join (',')
`` `
Many changes must be made directly while reading the file, especially the creation of an array of sessions and unique browsers. This would allow us to reduce the use of `map`, which creates new array objects. I also used `upcase!` Instead of `upcase` to change the value to a straight line. After refactoring the code, `report ['allBrowser'] looked like this:

`` `
report ['allBrowsers'] =
unique_browsers
  .sort
  .join (',')
`` `

Changing sessions to a hash, where key is the user id, and value is an array of sessions for this user who helped to get rid of the “select” method, which unexpectedly used a bunch of memory resources.
Now instead of `user_sessions = sessions.select {| session | session ['user_id'] == user ['id']} `we just used` user_sessions = session [user ['id']] `

After this optimization, the program for parsing the 1MB file started in 0.68 seconds.

### Your Find 4
`sort_by!` and `reverse!`, worked better than `sort` and` reverse` when creating `session dates` After that, the optimization of the program was completed in 0.48 seconds.

### Your Find 5
There is not much difference in the interpolation of lines between:
`user.sessions.map {| s | s [: time] .to_i} .sum.to_s << 'min.'`
and
`" # {session_time.sum} min. "`
It is also good to reduce duplication of code that uses `map`

### Your Find 6
It is better to use characters for hash keys instead of strings, because string keys will create individual objects each time they are used.

## Results
As a result of this optimization, we finally managed to process the data file.
It was possible to improve the system metric with
`` `
Finish in 50.6

rss before iteration: 75 MB
rss after iteration: 99 MB
`` `
  before
`` `

Finish in 0.38

rss before iteration: 13 MB
rss after iteration: 13 MB
`` `

## Protection against performance regress
We should check tha correctness of tests
We should not be any worse