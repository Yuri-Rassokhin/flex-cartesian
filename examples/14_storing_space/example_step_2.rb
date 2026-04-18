require 'flex-cartesian'

space = FlexCartesian.new(source: :csv, separator: ';', uri: "./examples/14_storing_space/chatgpt.csv", dimensions: [:tokens, :temperature] )

anchor = embed(space.data(:get, vector: { tokens: "20", temperature: "0.0" }, target: "response"))

space.func(:add, :response) { |v| space.data(:get, vector: v, target: "response") }
space.func(:add, :embedding, hide: true) { |v| embed(v.response) }
space.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }

space.func(:run)

#space.output(format: :csv, file: "chatgpt_embeddings.csv")

space.visualize(x: :temperature, y: :tokens, func: :semantic_shift, output: "./examples/14_storing_space/viz.html")

puts "HTML visualization has been saved in ./examples/14_storing_space/viz.html"

space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :semantic_shift)
