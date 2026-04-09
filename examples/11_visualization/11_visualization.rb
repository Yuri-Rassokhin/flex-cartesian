require 'flex-cartesian'

source = "./examples/11_visualization/yolo-arm-a1.xlsx"

space = FlexCartesian.new(source: :xlsx, uri: source, dimensions: [:iteration, :requests, :processes] )

space.func(:add, :inference) { |v| space.data(:get, vector: v, target: "collect_inference_time") }
space.func(:run)

space.visualize(
  format: :html,
  x: :requests,
  y: :processes,
  function: :inference,
  output: "./examples/11_visualization/viz.html",
  show_legend: false,
  show_z_title: false,
  show_grid: true,
  equal_axes: true,
  start_at_zero: true
)
