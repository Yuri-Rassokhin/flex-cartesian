require "informers"
require 'net/http'
require 'json'
require 'uri'

OPENAI_TOKEN = ENV["OPENAI_TOKEN"]

def llm(model: "gpt-4.1-mini", temperature:, messages:, max_tokens:)
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

