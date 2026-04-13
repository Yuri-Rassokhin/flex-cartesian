require 'flex-cartesian'
require_relative 'models'

# create parameter space for ChatGPT's behaviour
space = FlexCartesian.new({ temperature: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0], tokens: [20, 50, 100, 200, 400] })

# create test prompt for ChatGPT
msg = [
  { role: "system", content: "You are a precise and consistent assistant." },
  { role: "user", content: "Explain quantum mechanics in one sentence." }
]

anchor = nil

# DEFINE BEHAVIOURAL FUNCTIONS IN THE PARAMETER SPACE, FOR EACH COMBINATTION OF PARAMETERS:
# ChatGPT's responses
space.func(:add, :response) { |v| llm(temperature: v.temperature, max_tokens: v.tokens, messages: msg ).gsub(/[\r\n]+/, ' ').downcase.strip }
# semantic embeddings of the responses
space.func(:add, :embedding, hide: true) { |v| anchor ||= embed(v.response); embed(v.response) }
# quantified semantic shift from the very first response stored in `anchor`
space.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }

# compute all the functions in the parameter space
space.func(:run, progress: true, title: "Obtaining behavioural data")

# parameter space with behavioral functions is the behavioural model - we can visualize it
space.visualize(
  format: :html,
  x: :temperature,
  y: :tokens,
  function: :semantic_shift,
  output: "./viz.html",
  show_legend: false,
  show_z_title: true,
  show_grid: true,
  equal_axes: true,
  start_at_zero: true,
  show_plot_title: false
)

# finally, analyze how precisely parameters influence ChatGPT's response
a = space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42)
a.output(colorize:true, function: :semantic_shift)

