require 'flex-cartesian'
require_relative 'models'

# In the previous example #10 we created PBB, populated its function, and stored the PBB in that file:
path = "./examples/basic/10_saving_space/chatgpt.csv"

# Now we create PBB space from the raw data stored in `path`:
s = FlexCartesian.new(source: :csv, separator: ';', uri: path, dimensions: [:tokens, :temperature] )
s.func(:add, :response) { |v| s.source(:read, vector: v, target: "response") }

# Additionally, we define new functions in space `s`
s.func(:add, :embedding, hide: true) { |v| embed(v.response) }
anchor = embed(s.source(:read, vector: { tokens: "20", temperature: "0.0" }, target: "response"))
s.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }

# Calculate all the functions in space `s`
s.func(:run)

viz = "./examples/basic/11_reading_space/viz.html"
s.visualize(x: :temperature, y: :tokens, func: :semantic_shift, output: viz)

puts "Visualization saved to #{viz}"

s.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :semantic_shift)
