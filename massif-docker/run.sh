#!/bin/bash

docker run -it -v $(pwd):/tmp holyketzer/ruby-valgrind valgrind --tool=massif ruby run.rb
