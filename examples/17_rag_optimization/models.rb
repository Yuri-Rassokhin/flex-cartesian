# --- utilities ---
def embed(text, model)
  cache_key = "#{model}_#{text.hash}"
  return $embed_cache[cache_key] if $embed_cache[cache_key]

  vector = if model == "text-embedding-3-small"
    sleep 0.1 # Rate limit protection
    uri = URI("https://api.openai.com/v1/embeddings")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json", "Authorization" => "Bearer #{OPENAI_TOKEN}" })
    req.body = { model: model, input: text }.to_json
    res = JSON.parse(http.request(req).body)
    res.dig("data", 0, "embedding")
  else
    EMBEDDER.(text)
  end

  $embed_cache[cache_key] = vector
  vector
end

def llm(model: "gpt-4o", temperature: 0.1, messages:)
  uri = URI("https://api.openai.com/v1/chat/completions")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json", "Authorization" => "Bearer #{OPENAI_TOKEN}" })
  req.body = { model: model, temperature: temperature, max_tokens: 150, messages: messages }.to_json
  res = JSON.parse(http.request(req).body)
  raise "OpenAI API error: #{res["error"]["message"]}" if res["error"]
  res.dig("choices", 0, "message", "content").strip
end

def cosine(v1, v2)
  dot = v1.zip(v2).sum { |a, b| a * b }
  n1  = Math.sqrt(v1.sum { |x| x * x })
  n2  = Math.sqrt(v2.sum { |x| x * x })
  return 0.0 if n1.zero? || n2.zero?
  dot / (n1 * n2)
end

# symbol-based chunking - it's naive but will do for the demo
def chunk_text(text, size, overlap)
  chunks = []
  i = 0
  while i < text.length
    chunks << text[i, size]
    step = size - overlap
    i += (step > 0 ? step : size)
  end
  chunks
end

def retrieve(query, chunks, model, top_k)
  q_emb = embed(query, model)
  scored = chunks.map do |chunk|
    { chunk: chunk, score: cosine(q_emb, embed(chunk, model)) }
  end
  # sort by descending score and take top_k
  scored.sort_by { |s| -s[:score] }.first(top_k).map { |s| s[:chunk] }.join("\n...\n")
end

