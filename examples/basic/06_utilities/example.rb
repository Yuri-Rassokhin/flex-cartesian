require 'flex-cartesian'

s = FlexCartesian.new({ dim1: [1, 2], dim2: ['x', 'y'], dim3: [true, false]})

# Calculate size of the space, with respect to conditions (if any)
puts "Total size of Cartesian space, excluding functions: #{s.size}"

# Convert vectors of the space s to arrays (first 3 vectors in this example)
puts "Convert first 3 vectors to array: #{s.to_a(limit: 3).inspect}"

# Show dimensions of the space
# NOTE: API has changed: .dimensions simply returns hash of dimensional values, it doesn't accept separator anymore
puts s.dimensions

# Show vectors as hash
# NOTE: .vector_to checks conditions and consistency of vectors
# Because of the checks, this method can be slow when combined with .cartesian, use it with caution
s.cartesian { |v| puts s.vector_to(v, :hash).inspect }

# show vectors as hash ignoring all vector checks
s.cartesian { |v| puts v.to_h.inspect }

