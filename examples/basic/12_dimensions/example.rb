require 'flex-cartesian'

s = FlexCartesian.new({ dim1: [1, 2], dim2: ['x', 'y'], dim3: [true, false]})

puts "\nSpace created:"
s.output

# dynamically add new dimensions
s.dim(:add, { dim4: [3, 4], dim5: ['a', 'b'] })

puts "\nTwo dimensions added to the space:"
s.output

s.dim(:del, :dim4)

puts "\nOne dimension removed from the space:"
s.output
