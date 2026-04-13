require 'flex-cartesian'
require "informers"

EMBEDDER = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

def embed(text)
  EMBEDDER.(text)
end

def cosine(v1, v2)
  dot = v1.zip(v2).sum { |a, b| a * b }
  n1  = Math.sqrt(v1.sum { |x| x * x })
  n2  = Math.sqrt(v2.sum { |x| x * x })
  return 0.0 if n1.zero? || n2.zero?
  dot / (n1 * n2)
end

space = FlexCartesian.new(source: :csv, separator: ';', uri: "./chatgpt_math.csv", dimensions: [:tokens, :temperature] )

anchor = embed(space.data(:get, vector: { tokens: "20", temperature: "0.0" }, target: "response"))

space.func(:add, :response) { |v| space.data(:get, vector: v, target: "response") }
space.func(:add, :embedding, hide: true) { |v| embed(v.response) }
space.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }

space.func(:run)

space.output(format: :csv, file: "chatgpt_embeddings.csv")

space.visualize(x: :temperature, y: :tokens, function: :semantic_shift, output: "./examples/13_chatgpt/viz.html")

space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(function: :semantic_shift)
