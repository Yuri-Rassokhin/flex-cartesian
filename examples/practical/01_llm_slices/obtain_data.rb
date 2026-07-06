require 'flex-cartesian'
require_relative 'models'

s = FlexCartesian.new({
  model: [ "gpt-4.1", "gpt-4o", "gpt-4o-mini" ],
  temperature: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  prompt: [
    "Explain quantum mechanics in one sentence",
    "Write a quatrain about war",
    "Solve 2+2"
  ],
  tokens: [20, 50, 100, 200, 400],
  iteration: [1, 2, 3, 4]
})

s.func(:add, :response) do |v|
  messages = [
    { role: "system", content: "You are a precise and consistent assistant." },
    { role: "user", content: v.prompt }
  ]
  llm(
    model: v.model,
    temperature: v.temperature,
    max_tokens: v.tokens,
    messages: messages
  ).gsub(/[\r\n]+/, ' ').delete(',;').downcase.strip
end

s.func(:add, :embedding, hide: true) { |v| embed(v.response) }
anchor = embed(s.source(:read, vector: { tokens: "20", temperature: "0.0" }, target: "response"))
s.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }

s.func(:run, title: "Probing LLM, #{space.size} runs")

path = "./examples/practical/01_llm_slices/chatgpt.csv"

space.output(format: :csv, file: path)
puts "\nParameter space saved to #{path}"
