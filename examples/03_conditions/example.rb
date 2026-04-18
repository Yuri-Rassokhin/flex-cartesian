require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
space = FlexCartesian.new(example)

# Add condition that allows only combinations where value in the 1st dimension is odd
space.cond(:set) { |v| v.dim1.odd? }
# Print the conditions in the parameter space
space.cond
# Print the parameter space with the condition applied, and show the size of Cartesian space after applying the condition
space.output
# See the size of parameter space changed by the condition
puts "Size with conditions: #{space.size}"
# Remove the condition using its index in order of setting conditions, starting from zero
space.cond(:unset, index: 0)
# Remove all conditions, if any
space.cond(:clear)
# See the size of parameter space restored to default size of the full space
puts "Restored size of full space: #{space.size}"
# Set condition based on function result - highly useful for isosurfaces and such
puts "Setting function with condition"
space.func(:add, :example) { |v| v.dim1 + (v.dim3 ? 2 : 3) }
space.func(:run)
space.cond(:set) { |v| space.function(v, :example) <= 3 }
space.output

