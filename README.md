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

