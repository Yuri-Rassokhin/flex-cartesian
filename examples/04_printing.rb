require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

# PRINT PARAMETER SPACE

# Print parameter space and all functions evaluated
s.output
# Same as above, as Markdown
s.output(format: :markdown)
# Same as above, as CSV
s.output(format: :csv)

