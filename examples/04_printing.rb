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
# Print dimension names only
puts "#{s.dimensions(values: false, separator: ' ')}"
# print all combinations of the parameter space with dimension names and values
s.cartesian { |v| puts s.dimensions(v, separator: ' ') }

