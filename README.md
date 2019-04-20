# Users statistics calculator

## Problem
In our project we have a problem of calculating statistics for users. Report works with a large files without any signs
of work could be done in reasonable time. That is why we think that we should check this report for bottlenecks and fix 
them if they are exist.

## Warranty of correctness of work
We have tests that verify correct logic of the algorithm and assure that we won't go wrong.

## Feedback loop
We implemented logic that measures our algorithm by iterations per time on a sample of data of 65kb size. So after 
evaluation of this metric we will seek for bottlenecks with help of various cpu and memory profilers. When we'll find any
of these bottlenecks and fix them we'll reevaluate this metric and repeat these steps until we'll have algorithm that don't
bother us.

## Step 1
I tried to turn off GC in our sample test and check whether memory issues could cause such problems with the speed.
Metrics didn't change a lot hence i understood that main problem for now is in algorithm by itself and we should seek 
where CPU works mostly. Maybe we could apply certain optimization there. Additionally we disabled GC to be focused only 
in algorithm issue.

After all measures we figured out the problem in sequential looping over an array without any using of ids for fast search.

## Step 2
After refactoring in step1 where i replaced sequential looping through array with using of ids i reduced algorithm
complexity at least x3. I applied stackprof and rubyprof once more for checking what we've got for now and next problem we
saw using of all? method for checking of existing sessions in presaved array.

## Step 3
We applied set data structure for making unique assembling for us. After next measures we saw problem with date parsing
in the final part of the report.

## Step 4 
Exactly in our case this part of algorithm do nothing so we excluded it without any breaking of law. Finally we are at
the point where we can't gain much of performance with simple refactorings. It's a good moment for capturing our memory 
situation in terms of waisting it. So after measures i see that we have a lot of redundant array allocations. 

## Step 5
After removing all obvious places of redundant array allocations i used frozen_string_literal for avoiding allocations of 
redundant strings

## Step 6 - Final result
All my next steps were connected with looking why memory using grows lineally to 400mb score and stops on that mark. The
problem was that profilers didn't tell much about that just were showing that number of allocating object were extremely
high. Finally i have figured out with massif-visualizer that all allocating memory related with collecting browsers and 
i fixed it with using set. After that i used refactoring for decomposing all logic by domains area.

Before refactoring i had result with using 37mb total for large file
![Before refactoring](/optimizations/step10/before.png)
After refactoring memory usage grew but i think that in this case we don't need to dig deeper. This result is ok for us.
![After refactoring](/optimizations/step10/after.png)

Assuming in the result we have parser that handles the task in `9` sec with `46 mb` used.

Final asymptotic
    
    Warming up --------------------------------------
                    65kb    15.000  i/100ms
                   125kb     8.000  i/100ms
                   250kb     4.000  i/100ms
                    0.5m     2.000  i/100ms
                      1m     1.000  i/100ms
    Calculating -------------------------------------
                    65kb    159.165  (± 4.3%) i/s -    330.000  in   2.078575s
                   125kb     81.522  (± 8.3%) i/s -    168.000  in   2.095915s
                   250kb     45.831  (± 3.6%) i/s -     92.000  in   2.013734s
                    0.5m     24.744  (± 2.9%) i/s -     50.000  in   2.023426s
                      1m     12.841  (± 3.3%) i/s -     26.000  in   2.028261s
                      with 100.0% confidence
    
    Comparison:
                    65kb:      159.2 i/s
                   125kb:       81.5 i/s - 1.95x  (± 0.19) slower
                   250kb:       45.8 i/s - 3.47x  (± 0.20) slower
                    0.5m:       24.7 i/s - 6.43x  (± 0.34) slower
                      1m:       12.8 i/s - 12.39x  (± 0.65) slower
                      with 100.0% confidence 
                  
Comparing with what we had in the beginning

    Warming up --------------------------------------
                    65kb     1.000  i/100ms
                   125kb     1.000  i/100ms
                   250kb     1.000  i/100ms
                    0.5m     1.000  i/100ms
                      1m     1.000  i/100ms
    Calculating -------------------------------------
                    65kb     16.952  (± 4.2%) i/s -     34.000  in   2.015597s
                   125kb      5.178  (± 2.1%) i/s -     11.000  in   2.125509s
                   250kb      1.333  (± 2.0%) i/s -      3.000  in   2.251281s
                    0.5m      0.370  (± 0.0%) i/s -      1.000  in   2.703453s
                      1m      0.077  (± 0.0%) i/s -      1.000  in  13.051390s
                      with 100.0% confidence
    
    Comparison:
                    65kb:       17.0 i/s
                   125kb:        5.2 i/s - 3.27x  (± 0.15) slower
                   250kb:        1.3 i/s - 12.72x  (± 0.68) slower
                    0.5m:        0.4 i/s - 45.84x  (± 1.94) slower
                      1m:        0.1 i/s - 221.22x  (± 9.44) slower
                      with 100.0% confidence