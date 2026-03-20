require 'flex-cartesian'

# CREATE PARAMETER SPACE
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

# IMPORT TO AND EXPORT FROM PARAMETER SPACE

# Export dimensions of the parameter space to JSON file (same method for YAML)
s.export('example.json', format: :json)
# Import dimensions of the parameter space from JSON file (same method for YAML)
s.import('example.json').output

