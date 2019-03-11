#!/bin/bash

docker run -it -v $(pwd):/tmp -e DATA=data/data_20k.txt holyketzer/ruby-valgrind valgrind --tool=massif ruby run.rb
