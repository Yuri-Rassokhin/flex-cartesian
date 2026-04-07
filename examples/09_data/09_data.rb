require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "./examples/09_data/yolo-arm-a1.xlsx", dimensions: [:iterate_iteration, :infra_shape, :iterate_requests, :iterate_processes] )

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time") }
space.func(:run, progress: true, title: "Obtaining AI data")

analyzer = space.analyzer(:morris, trajectories: 1000, step: 0.1, seed: 31)
analyzer.output(function: :inference, colorize: true, format: :markdown)
