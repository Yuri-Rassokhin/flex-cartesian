<h1 align="center">FlexCartesian</h1>
<p align="center">
  <b>Model real systems as functions of parameters.<br>Extract behavioural blueprints.<br>Get insights with a few lines of code.</b>
</p>

---

# What Is It

FlexCartesian is a novel approach to parameter space analysis. It introduces the Parametric Behaviour Blueprinting paradigm, abbreviated as PBB.

# What Is It For

Most systems around us are functions of parameters.<br/>

The LLM you use has inference parameters, and its functions are response quality, response time, and throughput. The cloud storage you use has configuration parameters, and its functions are IOPS and throughput. Even the car you drive has driving parameters, and its function is cost per mile.

As a rule, a parametric system's behavior is characterized by its function. Naturally, you want to tune those parameters to bring the system to its absolute best operating mode: the lowest cost per mile, the highest storage IOPS, or the lowest response time from an LLM. This leads to two fundamental questions:

<p align="center">
<b>HOW DO PARAMETERS INFLUENCE THE BEHAVIOUR OF THE SYSTEM?</b>
</p>

<p align="center">
<b>WHAT IS THE ABSOLUTE BEST OPERATING MODE OF THE SYSTEM?</b>
</p>

FlexCartesian addresses both questions. It explores the behavior of your system and identifies its optimal operating modes.

# Why It Exists

FlexCartesian fills several practical gaps left by conventional benchmarking and parameter space analysis tools.

**> _Data gathering is separated from data analysis._**

Specifically, benchmarking tools blindly provide raw data, while modeling tools blindly assume that data has already been prepared somehow.
There is a need for a single tool that builds a model of a system and probes live data from it in a structured, consistent way that perfectly aligns with that model.

**> _Data gathered from systems is often scattered, inconsistent, unstructured, and incomplete._**

What's even worse, you rarely know in advance if there are gaps in the fetched data or where they might be.
There is a need for a tool that establishes a rigorous mathematical model of the system first, and then gathers data exactly as the model requires to represent the system consistently.

**> _System analysis is spread across System Engineer, System Architect, and Data Scientist roles._**

The first role knows how to benchmark and gather data. The second role understands the system's architecture. The third knows how to explore the data. There is a need for a simple tool that enables any of these roles to conduct full-cycle analysis without delays. For example, a System Architect should be able to iteratively run an analysis, updating the data in the model quickly and independently.

**> _Heavy-weight scripting is required to turn specialized libraries into end-user tools._**

There is a need for a high-level, concise Domain-Specific Language (DSL) to gather data, explore it, and model the parametric system.

# Essential Advantages

FlexCartesian elevates the traditional parameter space analysis paradigm to the next level, which we call **Parametric Behaviour Blueprinting (PBB)**.

Conventional parameter space analysis takes the existence of parameter values and system states for granted, focusing solely on exploring the state (sensitivity, robustness, trade-offs, extrema, heatmaps, etc.). PBB extends this scope further:

**1. Live data gathering.** FlexCartesian fetches data directly from a real system (digital or physical) using defined `behavioural functions`.
**2. Evolving blueprints.** A live linkage to the real system maintains a behavioural blueprint that evolves over time. This is driven by `data sources` feeding the behavioural functions, natively supporting the temporal dimension in the model.
**3. Structured Consistency.** FlexCartesian maintains the data gathered from the real system in a structured, complete order. This is enforced by FlexCartesian's core mathematical model: `parameter space` + `conditions` + `behavioural functions`. These three concepts guarantee that the system's behavior is described correctly for any valid combination of parameters.
**4. Reverse Linkage for Simulation.** FlexCartesian doesn't just use the live linkage to gather data; it allows you to use the blueprint as a substitute for the real system. This unlocks new opportunities in system modeling, testing, and integration. It is particularly useful for air-gapped systems or AI training, where providing real system data is unavailable or prohibitively expensive.

Additionally, FlexCartesian implements PBB via a highly expressive Ruby-based DSL. This allows you to execute powerful concepts in just a single line of code, natively integrating all the flexibility and elegance of Ruby.  

## Example #1: Avoiding semantic shift in ChatGPT

Suppose we want to find the optimal operating mode for ChatGPT—specifically, the ranges of `temperature` and `tokens` where the model gives stable, consistent answers to repeated questions. A lack of stability is known as _semantic shift,_ which is crucial to avoid in fields like law or science, where an AI assistant must provide reliable answers based on a strict corpus of documents.

Perhaps, we want to find optimal operating mode of ChatGPT - specifically, the ranges of its temperature and tokens where ChatGPT gives stable and consistent answers to repeated question. The lack of such stability is called semantic shift, which is crucial to avoid in such fields as law or science, where AI assistant must provide very stable answers based on a given corpus of documents.

While you can run [this example](https://github.com/Yuri-Rassokhin/flex-cartesian/tree/main/examples/13_chatgpt_semantic_shift) yourself, here's how FlexCartesian determines a semantic-shift-free operating mode, step by step.

Enable FlexCartesian:

```ruby
require 'flex-cartesian'
```

Define the parameter space:

```ruby
space = FlexCartesian.new({
		temperature: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
		tokens: [20, 50, 100, 200, 400]})
```

Define the behavioural function `response`. For any combination of parameters, it returns the response given by ChatGPT to the same test question:

```ruby
msg = [ { role: "system", content: "You are a precise and consistent assistant." },
        { role: "user", content: "Explain quantum mechanics in one sentence." } ]

space.func(:add, :response) { |v| llm(temperature: v.temperature, max_tokens: v.tokens, messages: msg ) }
```

Enrich the system with two additional behavioural functions. For any answer provided by `response`, the `embedding` function returns its vector embedding. The `semantic_shift` function then calculates how far the response drifts away from the very first answer ("anchor") given by the model. This value is exactly what we need!

```ruby
space.func(:add, :embedding) { |v| anchor ||= embed(v.response); embed(v.response) }
space.func(:add, :semantic_shift) { |v| (1.0 - cosine(v.embedding, anchor)).round(2) }
```

Next, we compute all the functions across the entire parameter space.
Behind the scenes, FlexCartesian iterates each function over all possible parameter combinations.

```ruby
space.func(:run, progress: true)
```

Upon completion, FlexCartesian holds the Parametric Behaviour Blueprint of our system.
Now, we can visualize this PBB as a 2D heatmap showing how the semantics of ChatGPT's answers depend on `tokens` and `temperature`

```ruby
space.visualize(x: :temperature, y: :tokens, func: :semantic_shift, output: "./viz.html")
```

When we open `./viz.html` in a browser, we see the semantic shift varying from `0.0` (identical to the first answer) to `1.0` (totally inconsistent):

<p align="center">
	<img src="docs/assets/viz/example-low-rate.gif" width="600"/>
</p>

The heatmap gives us our answer: to completely avoid semantic shift, we should keep the temperature at or below `0.2`.
The number of tokens has no measurable influence on response stability.
Notably, even at temperatures beyond `0.2`, the responses remain respectably consistent, with the shift barely reaching `0.2`.

Finally, we want to mathematically assess the influence of each parameter:

```ruby
space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :semantic_shift, format: :markdown)
```

This produces a Markdown table quantifying the influence of the parameters:

|parameter  |influence[semantic_shift]|deviation|probes|category|linearity        |recommendation                                                                                   |
|-----------|-------------------------|---------|------|--------|-----------------|-------------------------------------------------------------------------------------------------|
|tokens     |0.14                     |0.22     |10    |strong  |highly non-linear|critical parameter with complex interactions; prioritize for variance-based analysis (e.g. Sobol)|
|temperature|0.09                     |0.19     |10    |strong  |highly non-linear|critical parameter with complex interactions; prioritize for variance-based analysis (e.g. Sobol)|

This sensitivity table confirms the strong influence of both parameters and, most importantly, categorizes their influence as highly non-linear. This means we cannot make decisions based on just a few isolated probes. Instead, we must build a complete behavioural blueprint across the entire parameter space and find the "sweet spot": temperature <= 0.2, regardless of tokens.

## Example #2: Sensitivity of AWS DynamoDB servers

Let's look at [another example](https://github.com/Yuri-Rassokhin/flex-cartesian/tree/main/examples/09_ping_visualize). If we ping AWS DynamoDB, how do specific parameters influence the ping time? For this example, let's analyze geographic IP address and packet size.

Here is the full code showing how FlexCartesian finds the answer:

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

By running this code, you'll generate an interactive HTML heatmap `./viz.html` illustrating how geography and packet size affect ping times to DynamoDB.

As you can see, FlexCartesian's expressive DSL packs complex system profiling into simple one-liners.
If you need a mathematically rigorous assessment of these parameters, simply add one more line:

```ruby
space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(func: :time)
```

This applies [Morris sensitivity analysis](https://en.wikipedia.org/wiki/Morris_method) directly to the behavioural blueprint extracted by FlexCartesian.

## API Documentation

Detailed API documentation is available [here](docs/api/api.md).

## Installation

```bash
gem install flex-cartesian
```

## Status

This project is actively developed. Please [submit](https://github.com/Yuri-Rassokhin/flex-cartesian/issues) your feature requests or bug reports. 

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/Yuri-Rassokhin/flex-cartesian](https://github.com/Yuri-Rassokhin/flex-cartesian).

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to standard open-source etiquette.

## License

This project is licensed under the terms of the GNU General Public License v3.0. See [LICENSE](LICENSE) for more details.
