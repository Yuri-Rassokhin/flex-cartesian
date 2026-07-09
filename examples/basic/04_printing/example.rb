require 'flex-cartesian'

s = FlexCartesian.new({  dim1: [1, 2], dim2: ['x', 'y'], dim3: [true, false]})

# Print parameter space as a table with dimensions and functions (if any) as columns
# By default, .output prints the space as a plain textual table
s.output

# NOTE: When a function is added to space, it is not computed automatically
# For the function to obtain its values, call s.func(:run)
# If you run s.output and there are functions that have not enjoyed .func(:run) yet, their values will be `nil` in the output

# You can format the space as Markdown
s.output(format: :markdown)

# Also, you can format the space as CSV
s.output(format: :csv)

# By default, output is colorized (unless it's written to a file), but colorization can be disabled
# This is useful when you need to redirect output somewhere and would like to guarantee no artifacts caused by special signs
# Note that colorization is disabled automatically if .output takes a file name
s.output(format: :markdown, colorize: false)

