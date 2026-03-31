require 'flex-cartesian'

space = FlexCartesian.new(source: :xlsx, uri: "yolo.xlsx", dimensions: [:iterate_requests, :iterate_device])
space.output(format: :markdown, colorize: true)
