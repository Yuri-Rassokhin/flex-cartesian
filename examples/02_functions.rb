require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)



# FUNCTIONS IN PARAMETER SPACE

# Functions are evaluated on each combination of parameter space
# They can be treated as virtual dimensions in the output, but they do not affect the size of parameter space
# Functions are not real dimensions, but virtual constructs that are calculated on the fly for each combination of parameter space
# Add function `triple` that triples value of the 1st dimension if value in the 3rd dimension is true
s.func(:add, :triple) { |v| v.dim1 * (v.dim3 ? 3: 0) }
# Evaluate all functions in parameter space
s.func(:run)
# Remove function `triple`
s.func(:del, :triple)
# Add function `double` that will calculate first, before all other functions
s.func(:add, :double, order: :first) { |v| v.dim1 * 2 }
# Add function `decrement` that will calculate last, after all other functions
s.func(:add, :decrement, order: :last) { |v| v.dim1 - 1 }
# Add function `increment` to demonstrate that it will respect the order of functions, and it will calculate after `:first` and before `:last`
s.func(:add, :increment) { |v| v.dim1 + 1 }
# Print all functions in the parameter space
s.func
# `:first` and `:last` are relative orders, they do not fix the position of function in the order
# They only ensure that `:first` function will calculate before all other functions, and `:last` functions will calculate after all other functions
# So, if you add another function with `:first` order, it will overtake the order of the existing `:first` function
# Similarly, if you add another function with `:last` order, it will calculate after the existing `:last` function
# Ordering with `:first` and `:last` is useful for pre- and post-processing for each combination of parameter space

