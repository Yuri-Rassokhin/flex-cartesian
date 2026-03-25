require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)



# ITERATE OVER PARAMETER SPACE

def do_something(v)
  # do something here on vector v and its components 
end

# Dimensiality-agnostic iteration
s.cartesian { |v| do_something(v) }
# Dimensiality-aware iteration
s.cartesian { |v| puts "#{v.dim1} & #{v.dim2}" if v.dim3 }
s.output
# Show progress bar while iterating, useful for large parameter spaces
s.progress_each { |v| do_something(v) }
# Iterate in lazy moode without materializing entire Cartesian product in memory, useful for large parameter spaces
s.cartesian(lazy: true).take(2).each { |v| puts v.to_a.inspect }

