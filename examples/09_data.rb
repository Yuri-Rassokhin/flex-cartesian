require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "yolo.xlsx", dimensions:
                          [
                           :iterate_iteration,
                           :infra_shape,
                           :infra_cores,
                           :iterate_requests,
                           :iterate_processes,
                           :iterate_device
                          ]
        )

space.func(:add, :inference) { |v| data(:get, v, "collect_inference_time") }

space.output(format: :markdown, colorize: true)

