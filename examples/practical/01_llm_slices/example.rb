require 'flex-cartesian'
require_relative 'models'

path = "./examples/practical/01_llm_slices/chatgpt.csv"
s = FlexCartesian.new(source: :csv, separator: ';', uri: path, dimensions: [:tokens, :temperature] )
s.func(:add, :semantic_shift) { |v| s.source(:read, vector: v, target: "semantic_shift") }
s.func(:run)

viz = "./examples/practical/01_llm_slices/viz.html"

# fold `iteration` to its average to get rid of random noise
report = s.fold(:iteration) { |v| Stdlib.average(v).round(2) }

report_physics = report.where(prompt: "Explain quantum mechanics in one sentence")

view_gpt41 = report_physics.where(model: "gpt-4.1")

view_gpt41.visualize(x: :temperature, y: :tokens, func: :semantic_shift, output: viz)

report.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :semantic_shift)

