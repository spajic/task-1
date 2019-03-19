Metrics of deoptimized version 20_000 lines
Benchmarks
Calculating -------------------------------------
        Process 2500      4.440  (± 0.0%) i/s -     23.000  in   5.181137s
        Process 5000      1.295  (± 0.0%) i/s -      7.000  in   5.406855s
       Process 10000      0.363  (± 0.0%) i/s -      2.000  in   5.512669s
       Process 20000      0.069  (± 0.0%) i/s -      1.000  in  14.437365s
       Process 40000      0.012  (± 0.0%) i/s -      1.000  in  81.002661s

Comparison:
        Process 2500:        4.4 i/s
        Process 5000:        1.3 i/s - 3.43x  slower
       Process 10000:        0.4 i/s - 12.23x  slower
       Process 20000:        0.1 i/s - 64.11x  slower
       Process 40000:        0.0 i/s - 359.68x  slower

