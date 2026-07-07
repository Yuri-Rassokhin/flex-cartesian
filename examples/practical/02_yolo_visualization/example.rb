require 'flex-cartesian'

path = "./examples/practical/02_yolo_visualization/"
source = "#{path}/yolo-arm-a1.xlsx"

s = FlexCartesian.new(source: :xlsx, uri: source, dimensions: [:iteration, :requests, :processes] )

s.func(:add, :inference) { |v| s.source(:read, vector: v, target: "collect_inference_time") }
s.func(:run)

s.visualize(x: :requests, y: :processes, func: :inference, output: "#{path}/viz.html")

puts "Visualization saved to #{path}/viz.html"
