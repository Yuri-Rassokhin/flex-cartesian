require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "test-yolo.xlsx", dimensions:
                          [
                           :iterate_iteration,
                           :infra_shape,
                           :infra_cores,
                           :iterate_requests,
                           :iterate_processes,
                           :iterate_device
                          ]
        )

#puts space.index_show.inspect
#space.cartesian { |v| puts space.data(:get, vector: v, target: "collect_inference_time") }

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time") }
space.func(:run)

space.output(format: :markdown, colorize: true)

analyzer = space.analyzer(:morris, trajectories: 10, step: 1, seed: 42)
puts "\nWe apply #{analyzer.name}. #{analyzer.description}.\n\n"
puts "\n#{analyzer.name}: trajectories = 5, step = 1, seed = 42"
