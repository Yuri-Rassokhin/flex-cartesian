require 'flex-cartesian'
require 'informers'
require 'net/http'
require 'json'
require 'uri'
require_relative 'models'



OPENAI_TOKEN = ENV["OPENAI_API_KEY"]
raise "Missing OPENAI_API_KEY environment variable" unless OPENAI_TOKEN

# --- RAG SETTINGS ---

# test corpus of knowledge about fictituous technology
# we'll check if RAG will retrieve facts correctly
CORPUS = <<~TEXT
  Проект X-Prime был запущен в 2023 году для решения проблем распределенных транзакций.
  Основной алгоритм консенсуса в X-Prime называется 'Byzantine Vortex'. Он позволяет 
  достигать согласия за 12 миллисекунд при условии не более 3 византийских узлов.
  Система использует формат хранения данных 'NovaBlock', который сжимает индексы на 40% 
  эффективнее стандартного B-Tree. Для обеспечения сетевой изоляции X-Prime использует 
  технологию 'Quantum Mesh', которая динамически перестраивает топологию при потере пакетов.
  Главным недостатком X-Prime является высокое потребление оперативной памяти: 
  около 4GB на каждый активный узел в режиме простоя.
TEXT

QUERY = "Как называется алгоритм консенсуса в X-Prime и каково его время отклика?"
GROUND_TRUTH = "Алгоритм консенсуса называется Byzantine Vortex, он достигает согласия за 12 миллисекунд."

# initialize local model
EMBEDDER = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

# basic caching - this avoids running same requests to/from OpenAI for each batching configuration
$embed_cache = {}

# compute embedding of the golden example, in advance
TRUTH_EMBED = embed(GROUND_TRUTH, "text-embedding-3-small")



# Initialize an empty PBB space for our RAG
space = FlexCartesian.new({
  chunk_size: [50, 100, 150, 200, 250, 300], # size of text chunk (it influences the context-awareness)
  chunk_overlap: [0, 10, 20, 30, 40, 50], # overlapping (it influences the coherence of the entire chain of chunks)
  top_k: [1, 2, 3, 4, 5],           # number of retrieved chunks
#  embedding_model: ["all-MiniLM-L6-v2", "text-embedding-3-small"]
})

# 1. Split the knowledge corpus to chunks
space.func(:add, :chunks, hide: true) { |v| chunk_text(CORPUS, v.chunk_size, v.chunk_overlap) }

# 2. Find relevant context
space.func(:add, :retrieved_context, hide: true) do |v|
  retrieve(QUERY, v.chunks, "text-embedding-3-small", v.top_k)
#  retrieve(QUERY, v.chunks, v.embedding_model, v.top_k)
end

# 3. Generate LLM response for this context
space.func(:add, :llm_response, hide: true) do |v|
  prompt = "Use the following context to answer the query in Russian.\nContext: #{v.retrieved_context}\nQuery: #{QUERY}"
  msg = [
    { role: "system", content: "You are a precise technical assistant. Answer strictly based on the context." },
    { role: "user", content: prompt }
  ]
  llm(model: "gpt-4o-mini", temperature: 0.5, messages: msg)
end

# 4. Quality assessment: vectorize the response and compared to the golden response
space.func(:add, :eval_embedding, hide: true) { |v| embed(v.llm_response, "text-embedding-3-small") }
space.func(:add, :accuracy) { |v| cosine(v.eval_embedding, TRUTH_EMBED).round(4) }

# 5. Compute the cose: how many symbols/tokens are we feeding to prompt?
space.func(:add, :context_length) { |v| v.retrieved_context.length }

# Compute the entire PBB
space.func(:run, progress: true, title: "Profiling RAG Pipeline")

# Visualize the heatmap: how do the chunk size and top_k influence the accuracy?
space.visualize(
  x: :chunk_size, 
  y: :top_k, 
  func: :accuracy, 
  output: "./rag_tuning_viz.html"
)

puts "Heatmap saved to ./rag_tuning_viz.html"

#space.dim(:del, :embedding_model)

# Morris analysis: which parameter influences RAG accuracy most - model, chunk size, or top_k?
space.analyzer(:morris, trajectories: 10, step: 0.4, seed: 42).output(func: :accuracy, format: :markdown)
