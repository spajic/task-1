Change User object to Hash and prepare it during parsing of data file
 Benchmarks
Calculating -------------------------------------
        Process 2500     15.172  (± 0.0%) i/s -     76.000  in   5.013664s
        Process 5000      7.297  (± 0.0%) i/s -     37.000  in   5.073320s
       Process 10000      3.434  (± 0.0%) i/s -     18.000  in   5.248135s
       Process 20000      1.709  (± 0.0%) i/s -      9.000  in   5.271037s
       Process 40000      0.837  (± 0.0%) i/s -      5.000  in   5.983866s
       Process 80000      0.402  (± 0.0%) i/s -      3.000  in   7.485948s

Comparison:
        Process 2500:       15.2 i/s
        Process 5000:        7.3 i/s - 2.08x  slower
       Process 10000:        3.4 i/s - 4.42x  slower
       Process 20000:        1.7 i/s - 8.88x  slower
       Process 40000:        0.8 i/s - 18.12x  slower
       Process 80000:        0.4 i/s - 37.70x  slower

