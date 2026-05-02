require 'flex-cartesian'

example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}

s = FlexCartesian.new(example)

puts "\nSpace created:"
s.output

# dynamically add new dimensions
dims = { dim4: [3, 4], dim5: ['a', 'b'] }
s.dim(:add, dims)

puts "\nTwo dimensions added to the space:"
s.output

s.dim(:del, :dim4)

puts "\nOne dimension removed from the space:"
s.output
