require 'flex-cartesian'

s = FlexCartesian.new({ dim1: [1, 2], dim2: ['x', 'y'], dim3: [true, false]})

# You can save the schema of your dimensions to reuse it later
s.export('./examples/basic/05_import_export/example.json', format: :json)

# And here's how you reuse the schema of dimensions
s.import('./examples/basic/05_import_export/example.json').output

# NOTE: import/export only applies to dimensional schema - that is, dinmension names and dimensional values
# Functions, conditions, analyzers, and any other high-level constructs are not considered
# If you want to save an entire space, including functions, check out higher-level constructs such as data sources and space storing/loading

