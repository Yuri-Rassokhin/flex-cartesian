require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

puts "Total size of Cartesian space, excluding functions: #{s.size}"

puts "Convert first 3 vectors to array: #{s.to_a(limit: 3).inspect}"

puts s.dimensions

# show vectors as hash
# .vector_to checks conditions and consistency of vectors
s.cartesian { |v| puts s.vector_to(v, :hash).inspect }

# NOTE: API has changed - .dimensions simply returns hash of dimensional values
# the code below does not work anymore
#puts s.dimensions(separator: ' ')

# show vectors as hash ignoring all vector checks
s.cartesian { |v| puts v.to_h.inspect }
