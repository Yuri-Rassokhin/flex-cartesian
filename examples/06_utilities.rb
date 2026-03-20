require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

# UTILITIES

# Get size of parameter space, which is the number of combinations of dimensions that satisfy all conditions, and it does not include virtual constructs such as functions
puts "Total size of Cartesian space: #{s.size}"
# Convert parameter space to array, optionally limited to first N combinations
puts s.to_a(limit: 3).inspect

