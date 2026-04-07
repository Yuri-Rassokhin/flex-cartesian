require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

puts "Total size of Cartesian space, excluding functions: #{s.size}"

puts "Convert first 3 vectors to array: s.to_a(limit: 3).inspect"

s.cartesian { |v| puts s.dimensions(v, dimensions: true, values: true, separator: ' ') }

puts s.dimensions(separator: ' ')

s.cartesian { |v| puts v.to_a.inspect }
