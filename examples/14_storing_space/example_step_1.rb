require 'flex-cartesian'
require_relative 'models'

space = FlexCartesian.new({
   model: [ "gpt-4o-mini" ],
#  model: [ "gpt-4.1", "gpt-4o", "gpt-4o-mini" ],
   temperature: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  prompt: [
#    "Explain quantum mechanics in one sentence"
#    "Write a quatrain about war"
    "Solve 2+2"
  ],
  tokens: [20, 50, 100, 200, 400]
})

space.func(:add, :response) do |v|
  messages = [
    { role: "system", content: "You are a precise and consistent assistant." },
    { role: "user", content: v.prompt }
  ]

  llm(
    model: v.model,
    temperature: v.temperature,
    max_tokens: v.tokens,
    messages: messages
  ).gsub(/[\r\n]+/, ' ').downcase.strip
end

space.func(:run, progress: true, title: "Requesting  ChatGPT")

space.output(format: :csv, file: "./examples/14_storing_space/chatgpt.csv")
space.output(format: :markdown, colorize: true)
puts "\nParameter space has been saved in ./examples/14_storing_space/chatgpt.csv"

