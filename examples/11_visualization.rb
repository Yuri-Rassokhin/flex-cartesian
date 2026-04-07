require 'flex-cartesian'

name = "yolo-arm-a1"

space = FlexCartesian.new(source: :xlsx, uri: "#{name}.xlsx", dimensions:
                          [
                           :iterate_iteration,
                           :infra_shape,
                           :iterate_requests,
                           :iterate_processes
                          ]
        )

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time") }
space.func(:run)

analyzer = space.analyzer(:morris, trajectories: 1000, step: 0.1, seed: 31)

analyzer.output(function: :inference, colorize: true, format: :markdown)

space.visualize(format: :html, x: :iterate_requests, y: :iterate_processes, function: :inference, output: "viz.html")
