---
layout: default
title: FlexCartesian
nav_order: 1
description: Smart parameter exploration for Ruby
---

# FlexCartesian

## Stop running all combinations. Understand which ones matter.

FlexCartesian is a Ruby framework for intelligent parameter-space exploration.  
It helps you describe multidimensional benchmark spaces, execute experiments, and identify which parameters actually drive system behavior.

[View on GitHub](https://github.com/Yuri-Rassokhin/flex-cartesian)
[View on RubyGems](https://rubygems.org/gems/flex-cartesian)

---

## Why FlexCartesian?

Many parameter-sweep tools focus on one thing: running all combinations.

That works — until the search space becomes too large, too expensive, or simply too noisy to brute-force.

FlexCartesian takes a different approach:

- define parameter spaces in a human-readable way  
- derive commands and metrics directly in Ruby  
- execute benchmarks across multidimensional spaces  
- apply sensitivity methods such as Morris screening  
- discover which parameters matter most before scaling further  

In other words:

FlexCartesian is not just about enumerating combinations.  
It is about understanding the structure of the space.

---

## Core workflow

Parameter space  
→ Plan  
→ Execution  
→ Derived metrics  
→ Sensitivity analysis  
→ Decision  

---

## Simple example

### Input space

{
  "count": [2, 4],
  "size": [32, 64],
  "target": ["8.8.8.8", "1.1.1.1", "208.67.222.222"]
}

### Ruby code

require 'flex-cartesian'

s = FlexCartesian.new
s.import('ping.json')

result = {}

s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" }
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` }
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f }

s.plan(:morris, trajectories: 10, step: 1, seed: 42)
s.func(:run, progress: true, title: "Pinging")

s.sensitivity(metric: :time, recommend: true)

---

## Example output

parameter | importance | nonlinearity | mean   | n  | category                 | recommendation
target    | 41.50      | 43.70        | -41.44 | 10 | Strong nonlinear driver  | Further investigation with high precision
count     | 0.45       | 0.86         | -0.42  | 10 | Negligible               | Fix its value to reduce dimensionality
size      | 0.17       | 0.20         | -0.13  | 10 | Negligible               | Fix its value to reduce dimensionality

---

## Key features

- Human-friendly parameter spaces  
- Derived functions  
- Conditions  
- Lazy or eager iteration  
- Tabular output  
- Sensitivity analysis  

---

## Use cases

- AI / ML hyperparameter experiments  
- HPC benchmarking  
- cloud tuning  
- network performance testing  
- systems research  

---

## Philosophy

In complex systems, the most important thing is often not to run everything,  
but to discover what is worth running.

---

## Get started

gem install flex-cartesian

---

## License

GPL-3.0-only

