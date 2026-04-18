#!/usr/bin/bash

ex="01_iterators 02_functions 03_conditions 04_printing 05_import_export 06_utilities 07_ping 08_ping_analyzer 09_ping_visualize 10_ping_timestamp 11_data_sources 12_yolo_visualize 13_chatgpt_semantic_shift"

for i in $ex; do ruby ./examples/$i/example.rb; done
ruby ./examples/14_storing_space/example_step_1.rb
ruby ./examples/14_storing_space/example_step_2.rb
