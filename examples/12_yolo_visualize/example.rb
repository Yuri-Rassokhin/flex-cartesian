require 'flex-cartesian'

source = "./examples/12_yolo_visualize/yolo-arm-a1.xlsx"

space = FlexCartesian.new(source: :xlsx, uri: source, dimensions: [:iteration, :requests, :processes] )

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time") }
space.func(:run)

space.visualize(x: :requests, y: :processes, func: :inference, output: "./examples/12_yolo_visualize/viz.html")

puts "Visualization saved to ./examples/12_yolo_visualize/viz.html"
