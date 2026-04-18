require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "./examples/11_data_sources/yolo-arm-a1.xlsx", dimensions: [:iterate_iteration, :infra_shape, :iterate_requests, :iterate_processes] )

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time").to_f.round(2) }
space.func(:run, progress: true, title: "Importing YOLO data from XLSX document")

space.output(format: :markdown, colorize: true)
