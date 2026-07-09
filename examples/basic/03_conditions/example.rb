require 'flex-cartesian'

s = FlexCartesian.new({ dim1: [1, 2], dim2: ['x', 'y'], dim3: [true, false]})

# 1. Conditions are logical functions in the parameter space
# 2. Conditions determine valid vectors of the space
# 3. Conditions apply at the lowest level of abstration; once conditions are set,
# any other constructs in the space (iterators, functions, analyzers, etc.) apply to valid vectors only
# 4. There can be any number of conditions defined in the space
# 5. Multiple conditions apply as a logical AND

# NOTE: Conditions are very useful for setting natural restrictions for the dimensional values
# or for reflecting inter-dependencies between the dimensions
# Effectively, conditions allow you to work on a subset of the space: on a cube, sphere, and so forth

# Add condition that allows only vectors with odd value in the 1st dimension
s.cond(:set) { |v| v.dim1.odd? }

# Print all the conditions defined in the parameter space
s.cond

# If we print the space, it will only contain valid vectors
s.output

# Size of the space alse has changed because of restriction applied by the condition
puts "Size with conditions: #{s.size}"

# Remove the condition using its index in order of setting conditions (index starts from zero)
s.cond(:unset, index: 0)

# Remove all conditions (if any; do nothing, otherwise)
s.cond(:clear)

# See the size of parameter space restored to default size of the full space
puts "Restored size of full space: #{s.size}"

# Set condition based on a function result
# NOTE: this is highly useful for the analysis of isosurfaces and working with
# complex subsets of the space: curved or dynamically changing ones

# Step 1, define function in the space
s.func(:add, :example) { |v| v.dim1 + (v.dim3 ? 2 : 3) }
s.func(:run)

# Step 2, set the condition that is defined through the function
s.cond(:set) { |v| s.function(v, :example) <= 3 }
s.output

