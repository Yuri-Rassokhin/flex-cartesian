require 'flex-cartesian'
require 'net/http'
require 'json'
require 'uri'

OPENAI_TOKEN = ENV["OPENAI_TOKEN"]

def llm(model:, temperature:, messages:, max_tokens:)
  raise "Missing OPENAI_TOKEN" unless OPENAI_TOKEN

  sleep 0.2 # to respect API rate
  uri = URI("https://api.openai.com/v1/chat/completions")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path, {
    "Content-Type" => "application/json",
    "Authorization" => "Bearer #{OPENAI_TOKEN}"
  })

  request.body = {
    model: model,
    temperature: temperature,
    max_tokens: max_tokens,
    messages: messages
  }.to_json

  response = http.request(request)
  json = JSON.parse(response.body)

  # базовая защита от ошибок
  if json["error"]
    raise "OpenAI API error: #{json["error"]["message"]}"
  end

  json["choices"][0]["message"]["content"]
end

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

space.output(format: :csv, file: "chatgpt.csv")
space.output(format: :markdown, colorize: true)

