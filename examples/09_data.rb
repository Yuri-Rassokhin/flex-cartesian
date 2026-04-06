require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "yolo-arm-a1.xlsx", dimensions:
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

puts "We apply #{analyzer.name}."
puts "#{analyzer.description}."
puts

analyzer.output(function: :inference, colorize: true, format: :markdown)
analyzer.output(function: :inference, format: :csv, file: "result.csv")

