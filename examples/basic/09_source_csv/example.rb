require 'flex-cartesian'

data = "./examples/basic/09_source_csv/yolo-arm-a1.xlsx"

# When creating a space, you can connect it to a tabular data source
# This allows you to ingest dimensional schema directly from the data source
# The space will create dimensions and dimensional values from the values of the columns specified in `dimensions` below
s = FlexCartesian.new(
  source: :xlsx,
  uri: data,
  dimensions: [:iterate_iteration, :infra_shape, :iterate_requests, :iterate_processes]
)
# Now, space `s` is a 4D space formed by iterate_iteration, infra_shape, iterate requests, and iterate_processes table columns

# As the data source is linked to space `s`, you can define space functions through the data stored in the data source
# The method `.source` effectively extends semantic of functions to any external data sources
s.func(:add, :inference) { |v| s.source(:read, vector: v, target: "collect_inference_time").to_f.round(2) }

# As usual, the function obtains its values by calling `.func(:run)`
s.func(:run, progress: true, title: "Importing space function from XLSX document")

# Here's the space `s` - in a tabular output it looks like a sub-table of the external table
s.output(format: :markdown)

