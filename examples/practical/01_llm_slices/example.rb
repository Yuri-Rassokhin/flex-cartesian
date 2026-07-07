require 'flex-cartesian'
require_relative 'models'

path = "./examples/practical/01_llm_slices/"
src = "#{path}/chatgpt.csv"
viz = "#{path}/viz.html"

s = FlexCartesian.new(source: :csv, separator: ';', uri: src, dimensions: [:tokens, :temperature, :iteration, :prompt, :model] )
s.func(:add, :semantic_shift) { |v| s.source(:read, vector: v, target: "semantic_shift") }
s.func(:run, progress: true)

report = s.fold(:iteration) { |v| Stdlib.average(v).round(2) }

slice = {
  prompt: "Explain quantum mechanics in one sentence",
  model: "gpt-4o-mini"
}

view = report
            .where(slice)
            .visualize(x: :temperature, y: :tokens, func: :semantic_shift, output: viz)

report.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :semantic_shift)

