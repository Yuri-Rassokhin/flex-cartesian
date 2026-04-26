#!/usr/bin/bash

ex="01_iterators 02_functions 03_conditions 04_printing 05_import_export 06_utilities 07_ping 08_ping_analyzer 09_ping_visualize 10_ping_timestamp 11_data_sources 12_yolo_visualize 13_chatgpt_semantic_shift"

for i in $ex; do echo && echo "EXAMPLE: $i" && ruby ./examples/$i/example.rb; done
echo
echo "EXAMPLE: 14, step 1" && ruby ./examples/14_storing_space/example_step_1.rb
echo
echo "EXAMPLE: 14, step 2" && ruby ./examples/14_storing_space/example_step_2.rb
