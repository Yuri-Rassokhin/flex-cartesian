require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "./examples/11_visualization/yolo-arm-a1.xlsx", dimensions: [:iterate_iteration, :infra_shape, :iterate_requests, :iterate_processes] )

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time") }
space.func(:run)

space.visualize(format: :html, x: :iterate_requests, y: :iterate_processes, function: :inference, output: "./examples/11_visualization/viz.html", show_legend: false, show_z_title: false, show_grid: true)
