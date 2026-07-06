require 'flex-cartesian'

# Dimensions
dimensions = { dim1: [1, 2], dim2: ['x', 'y'], dim3: [true, false] }

# Create PBB (Parametric Behaviour Blueprint) space
s = FlexCartesian.new(dimensions)

# Dimensionality-agnostic: iterate over vectors of the space s
s.cartesian { |v| puts v.to_a.inspect }

# Dimensionality-agnostic: iterate over vectors and perform actions on vector components
s.cartesian { |v| puts "#{v.dim1} & #{v.dim2}" if v.dim3 }

# Iterate with progress bar: title of the progress bar will be `Testing`
s.cartesian(title: "Testing"){ |v| "#{v.dim1 * 2}" }

# Iterate with progress bar: `progress` flag enables progress bar without a title
s.cartesian(title: "Testing"){ |v| "#{v.dim1 * 2}" }

# NOTE: Progress bar is very useful for large spaces, when iteration takes time

# Iterate in lazy mode without materializing entire Cartesian product in memory
s.cartesian(lazy: true).take(2).each { |v| puts v.to_a.inspect }

# NOTE: Lazy mode is convenient for large parameter spaces

# Output space `s` as a Markdown table
s.output(format: :markdown)

