require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

# Print parameter space and all functions evaluated
s.output
s.output(format: :markdown)
s.output(format: :csv)

