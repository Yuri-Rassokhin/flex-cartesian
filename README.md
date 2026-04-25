<h1 align="center">FlexCartesian</h1>
<p align="center">
  <b>Model real systems as functions of parameters.<br>Extract behavioural blueprints.<br>Get insights with a few lines of code.</b>
</p>

---

# What Is It

FlexCartesian is a new approach for parameter space analysis. It introduces Parametric Behaviour Blueprinting paradigm, abbreviated BPP.

# What Is It For

Most of the systems around us _are_ functions of parameters.<br/>

The LLM you are using has inference parameters, and its functions are quality of response, responce time, and throughput.
The cloud storage you are using has configuration parameters, and its functions are IOPS and throughput.
Even the car you are driving has driving parameters, and its function is cost per mile.

As a pattern, the behaviour of parameteric system behaviour characterizes by its function - and you want to tune parameters to bring the function to the absolute best operating mode: lowest cost per mile - highest storage IOPS - lowest response time from LLM. Hence the fundamental problems:<br/>

<p align="center">
<b>1. HOW DO PARAMETERS INFLUENCE THE BEHAVIOUR OF THE SYSTEM?</b>
</p>

<p align="center">
<b>2. WHAT IS THE ABSOLUTE BEST OPERATING MODE OF THE SYSTEM?</b>
</p>

FlexCartesian addresses both questions. It explores behaviour of your system and identifies optimal operating modes.

# Why It Exists

I created FlexCartesian to solve several practical issues of the performance benchmarking.

**AS IS** Data gathering is separated from the modelling. Specifiсally, modelling tools blindly assume that some data have been prepared somehow.

**THE NEED** One tool to build the model of a system and to probe the data from the live system in a structured, consistent way, and in accordance with the model.

**AS IS** Data fetched from the system were scatter, chaotic, unstructured, and incomplete. What's event worse, you never know in advance if/where there are gaps in the fetched data.

**THE NEED** A tool that puts rigour mathematical model of the system at first place - and then gathers the data as the model requires to represent the system consistently.

**AS IS** Disconnected professional roles: System Engineer knows how to benchmark and gather data - Data Scientist knows how to explore the data - System Architect nows how to model the system.

**THE NEED** System Architect has a tool to iteratively run this cycle, backing the system modelling with rock-solid data.

**AS IS** Heavey-weight scripting to integrate specialized libraries to one tool.

**THE NEED** High-level and concise DSL to gather data, explore the data, and model the parametric system.

## Essential Advantages

FlexCartesian extends the paradigm known as **parameter space analysis** to the next level we call **Parametric Behaviour Blueprinting (PBB)**.

Conventional parameter space analysis takes the existence of parameter values and system state for these values as granted - and it focuses on exploration of the system state (sensitivity, robustness, trade-offs, extrema, heatmaps, and so forth). PBB extends this scope further:

1. Gathering data from a real system (digital or physical). This is implemented by the _behavioural functions_.
2. A live linkage to the real system maintains a _behavioural blueprint_ that evolves in time. This is implemented by the _data sources_ available for the behavioural functions, which enables behavioural functions for the live data gathering, and the fact temporal dimension is natively supported in the model.
3. Maintaining the data gathered from the real system in a structured, consistent, and complete order. This is implemented by the mathematical model in the core of FlexCartesian: parameter space + conditions + behavioural functions. These three core concepts guarantee correctly described behaviour of the system for any valid combination of the parameters.
4. FlexCartesian not only uses live linkage between parametric behavioural blueprint and the real system to gather data. It allows to use the linkage in reverse - effectively, using the behavioural blueprint sa a substitute of the real system. This creates new opportunities in the system modelling, testing, and integration. Particularly, it is useful in air-gapped systems, and for AI training where provision of a real system data isn't available or prohibitively expensive.     

Additionally, FlexCartesian implements PBB in a very high-level Ruby-based DSL. This enables very powerful concepts in just one line of code. At the same time, FLexCartesian natively integrates all the flexibity and elegance of Ruby.   

## Example #1: Avoiding semantic shift in ChatGPT

Perhaps, we want to find optimal operating mode of ChatGPT - specifically, the ranges of its temperature and tokens where ChatGPT gives stable and consistent answers to repeated question. The lack of such stability is called semantic shift, which is crucial to avoid in such fields as law or science, where AI assistant must provide very stable answers based on a given corpus of documents. While you can run [this example](https://github.com/Yuri-Rassokhin/flex-cartesian/tree/main/examples/13_chatgpt_semantic_shift) yourself, here's how FlexCartesian suggests ChatGPT's operating mode free from semantic shift, step by step.

Enable FlexCartesian:

```ruby
require 'flex-cartesian'
```

Define parameter space:

```ruby
space = FlexCartesian.new({
		temperature: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
		tokens: [20, 50, 100, 200, 400]})
```

Define behavioural function `response` - for any combinations of parameters, it returns response given by ChatGPT to the same test question.

```ruby
msg = [ { role: "system", content: "You are a precise and consistent assistant." },
        { role: "user", content: "Explain quantum mechanics in one sentence." } ]

space.func(:add, :response) { |v| llm(temperature: v.temperature, max_tokens: v.tokens, messages: msg ) }
```

Enrich the system by two more behavioural functions.
For any answer provided by `response` function, the function `embedding` returns its vector embedding, and `semantic_drift` calculates how far the response drifts away from the very first answer (`anchor`) given by ChatGPT. The values of `semantic_shift` is precisely what we need!

```ruby
space.func(:add, :embedding) { |v| anchor ||= embed(v.response); embed(v.response) }
space.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }
```

Then we compute all the functions in the entire parameter space.
Behind the scene, FlexCartesian iterates each function over all combinations of parameters.

```ruby
space.func(:run. progress: true)
```

Upon completion, FlexCartesian holds PBB (Parametric Behavioural blueprint) of our system, ChatGPT.
Now we can visualize PBB as a fancy 2D-heatmap showing how semantic of ChatGPT's answers depends on tokens and temperature.

```ruby
space.visualize(x: :temperature, y: :tokens, func: :semantic_shift, output: "./viz.html")
```

We can open this `./viz.html` in a browser.
The semantic shift varies from 0.0 (the answer is identical to the first answer) to 1.0 (the answer is totally inconsistent from the first answer):

<p align="center">
	<img src="docs/assets/viz/example-low-rate.gif" width="600"/>
</p>

The heatmap suggests the answer to the initial question. To avoid semantic shift completely, we should keep temperature not exceeding 0.2, while the number of tokens has no influence to the responses at all. By the way, even with the temperatures beyond 0.2, the answering is still respectably consistent - the semantic shift hardly reaches 0.2.

Finally, we want to assess the influence of each parameter on the semantic shift of ChatGPT's answers.

```ruby
space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :semantic_shift, format: :markdown)
```

This will produce Markdown table of the quantified influence and the nature of influence of the parameters:

|parameter  |influence[semantic_shift]|deviation|probes|category|linearity        |recommendation                                                                                   |
|-----------|-------------------------|---------|------|--------|-----------------|-------------------------------------------------------------------------------------------------|
|tokens     |0.14                     |0.22     |10    |strong  |highly non-linear|critical parameter with complex interactions; prioritize for variance-based analysis (e.g. Sobol)|
|temperature|0.09                     |0.19     |10    |strong  |highly non-linear|critical parameter with complex interactions; prioritize for variance-based analysis (e.g. Sobol)|

This sensitivity table confirms strong influence of both parameters on the consistency of the answers, and most importantly, it categorizes their influence as highly non-linear. Therefore, we should NOT make decisions on these parameters based on a few probes - to the contrary, we have to build complete behavioural bluepring using entire parameter space - and find sweet area on it: "temperature <= 0.2, no matter the tokens".

## Example #2: Sensitivity of AWS DynamoDB servers

Let's take [another example](https://github.com/Yuri-Rassokhin/flex-cartesian/tree/main/examples/09_ping_visualize).
If we ping AWS DynamoDB, how do ping parameters influence ping time?
For the sake of example, let's take IP address and packet size.
Here's full code, showing how FlexCartesian gives the answer.

```ruby
# enable FlexCartesian
require 'flex-cartesian'

# define parameter space
space = FlexCartesian.new({
  size: [64, 512, 1400, 1500, 4096, 8192],
  target: [ "dynamodb.eu-central-1.amazonaws.com",   # Frankfurt
	    "dynamodb.us-east-1.amazonaws.com",      # Virginia, US
	    "dynamodb.sa-east-1.amazonaws.com",      # Sao Paolo
	    "dynamodb.ap-northeast-1.amazonaws.com", # Tokio
	    "dynamodb.af-south-1.amazonaws.com"]})   # Capetown

# define behavioural functions:
# 1. 'command' constructs ping command
# 2. 'raw' executes the command and returns raw result
# 3. 'time' extracts ping time from the result
# 4. 'cap' is a fancy stuff, it shows 150 ms ping threshold on the future visialization.
result = {}
space.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} -i #{v.interval} #{v.target}" }
space.func(:add, :raw, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` }
space.func(:add, :time) { |v| v.raw[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) }
space.func(:add, :cap) { |v| 150 }

# Now we compute all the functions in the parameter space
space.func(:run, progress: true)

# Visualize behavioural blueprint as a 2D-heatmap
# It will show two functions - ping time (:time) and 150ms threashold (:cap)
space.visualize(x: :size, y: :target, func: [ :time, :cap ], output: "./viz.html")
```

Just run this code, and you'll get an interactive HTML heatmap `./viz.html` showing how geography and packet size influence ping to DynamoDB.
As you can see, FlexCartesian enables very high-level and powerful DSL, packing complex operations to one-liners.
If you need mathematically rigorous assessment of the parameter influence, you just add yet another one-liner:

```ruby
space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :time)
```

This one-liner applies [Morris sensitivity analysis](https://en.wikipedia.org/wiki/Morris_method) to the behavioural blueprint extracted by FlexCartesian.

## API Documentation

Please have it [here](docs/api/api.md).

## Installation

```bash
gem install flex-cartesian
```

## Status

The project has been actively developed. Please [submit](https://github.com/Yuri-Rassokhin/flex-cartesian/issues) your feature requests or bug reports. 

## License

This project is licensed under the terms of the GNU General Public License v3.0. See [LICENSE](LICENSE) for more details.
