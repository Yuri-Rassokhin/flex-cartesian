require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)



# CONDITIONS IN CARTESIAN SPACE

# Condition is a logical constraint for allowed combinations of parameter space
# It returns true for allowed combinations of parameter space, and false for disallowed combinations
# Condition filters parameter space, so only combinations that satisfy the condition are included in the output, function evaluation, and in the size of Cartesian space
# You can have multiple conditions, and they will be combined with logical AND, so only combinations that satisfy ALL conditions will be included in the output and in the size of parameter space

# Add condition that allows only combinations where value in the 1st dimension is odd
s.cond(:set) { |v| v.dim1.odd? }
# Print the conditions in the parameter space
s.cond
# Print the parameter space with the condition applied, and show the size of Cartesian space after applying the condition
s.output
# See the size of parameter space changed by the condition
puts "Size with conditions: #{s.size}"
# Remove the condition using its index in order of setting conditions, starting from zero
s.cond(:unset, index: 0)
# Remove all conditions, if any
s.cond(:clear)
# See the size of parameter space restored to default size of the full space
puts "Restored size of full space: #{s.size}"

