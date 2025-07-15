# FlexCartesian

**Ruby implementation of flexible and human-friendly operations on Cartesian products**  

## Features

✅ Named dimensions with arbitrary keys

✅ Enumerate over Cartesian space with a single block argument  

✅ Actions on Cartesian are decoupled from dimensionality: `s.cartesian { |v| do_something(v) }`

✅ Conditions for Cartesian space: `s.cond(:set) { |v| v.dim1 > v.dim2 } }`

✅ Calculation over named dimensions: `s.cartesian { |v| puts "#{v.dim1} and #{v.dim2}" }`

✅ Functions on Cartesian space: `s.func(:add, :my_sum) { |v| v.dim1 + v.dim2 }`

✅ Lazy and eager evaluation

✅ Progress bars for large Cartesian spaces

✅ Export of Cartesian space to Markdown or CSV

✅ Import of Cartesian space from JSON or YAML

✅ Export of Cartesian space to Markdown or CSV

✅ Structured and colorized terminal output  

## Use Cases

`FlexCartesian` is especially useful in the following scenarios.

### 1. Sweep Analysis of Performance

Systematically evaluate an application or algorithm across all combinations of parameters:

- Parameters: `threads`, `batch_size`, `backend`, etc
- Metrics: `throughput`, `latency`, `memory`
- Output: CSV or Markdown tables

### 2. Hyperparameter Tuning for ML Models

Iterate over all combinations of hyperparameters:

- Examples: `learning_rate`, `max_depth`, `subsample`, `n_estimators`
- With constraints (e.g., `max_depth < 10 if learning_rate > 0.1`)
- With computed evaluation metrics like `accuracy`, `AUC`, etc

### 3. Infrastructure and System Configuration

Generate all valid infrastructure configurations:

```ruby
region:   ["us-west", "eu-central"]
tier:     ["basic", "pro"]
replicas: [1, 3, 5]
```

With conditions like "basic tier cannot have more than one replica:
```ruby
s.cond(:set) { |v| (v.tier == "basic" ? v.replicas == 1 : true) }
```

### 4. Mass Testing of CLI Commands
Generate and benchmark all valid CLI calls:

```bash
myapp --threads=4 --batch=32 --backend=torch
```

Capture runtime, output, errors, etc.

### 5. Input Generation for UI/API Testing
Automatically cover input parameter spaces for:

- HTTP methods: ["GET", "POST"]
- User roles: ["guest", "user", "admin"]
- Language settings: ["en", "fr", "de"]

### 6. Scientific and Engineering Simulations
Generate multidimensional experimental spaces for:

- Physics simulations
- Bioinformatics parameter sweeps
- Network behavior modeling, etc

### 7. Structured Reporting and Visualization
Output Cartesian data as:

- Markdown (for GitHub rendering)
- CSV (for Excel, Google Sheets, and more advanced BI tools)
- Plain text (for CLI previews)

### 8. Test Case Generation
Use it to drive automated test inputs for:

- RSpec shared examples
- Minitest table-driven tests
- PyTest parameterization

## Installation

```bash
bundle install
gem build flex-cartesian.gemspec
gem install flex-cartesian-*.gem
```



## Usage

```ruby
#!/usr/bin/ruby

require 'flex-cartesian'



# BASIC CONCEPTS

# 1. Cartesian object is a set of combinations of values of dimansions.
# 2. Dimensions always have names.

puts "\nDefine named dimensions"
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}

puts "\nCreate Cartesian space"
s = FlexCartesian.new(example)

def do_something(v)
  # do something here on vector v and its components 
end



# ITERATION OVER CARTESIAN SPACE

# 3. Iterator is dimensionality-agnostic, that is, has a vector syntax that hides dimensions under the hood.
#    This keeps foundational code intact, and isolates modifications in the iterator body 'do_something'.
# 4. For efficiency on VERY largse Cartesian spaces, there are
#    a). lazy evaluation of each combination
#    b). progress bar to track time-consuming calculations.

puts "\nIterate over all Cartesian combinations and execute action (dimensionality-agnostic style)"
s.cartesian { |v| do_something(v) }

puts "\nIterate over all Cartesian combinations and execute action (dimensionality-aware style)"
s.cartesian { |v| puts "#{v.dim1} & #{v.dim2}" if v.dim3 }

puts "\nIterate and display progress bar (useful for large Cartesian spaces)"
s.progress_each { |v| do_something(v) }

puts "\nIterate in lLazy mode, without materializing entire Cartesian product in memory"
s.cartesian(lazy: true).take(2).each { |v| do_something(v) }



# FUNCTIONS ON CARTESIAN SPACE

# 5. A function is a virtual dimension that is calculated based on a vector of base dimensions.
#    You can think of a function as a scalar field defined on Cartesian space.
# 6. Functions are printed as virtual dimensions in .output method.
# 7. However, functions remains virtual construct, and their values can't be referenced by name
#    (unlike regular dimensions). Also, functions do not add to .size of Cartesian space.

puts "\nAdd function 'triple'"
puts "Note: function is visualized in .output as a new dimension"
s.func(:add, :triple) { |v| v.dim1 * 3 + (v.dim3 ? 1: 0) }
# Note: however, function remains a virtual construct, and it cannot be referenced by name
s.output

puts "\Add and then remove function 'test'"
s.func(:add, :test) { |v| v.dim3.to_i }
s.func(:del, :test)



# CONDITIONS ON CARTESIAN SPACE

# 8. A condition is a logical constraint for allowed combitnations of Cartesian space.
# 9. Using conditions, you can take a slice of Cartesian space.
#    In particular, you can reflect semantical dependency of dimensional values.

puts "Build Cartesian space that includes only odd values of 'dim1' dimension"
s.cond(:set) { |v| v.dim1.odd? }
puts "print all the conditions in format 'index | condition '"
s.cond
puts "Test the condition: print the updated Cartesian space"
s.output
puts "Test the condition: check the updated size of Cartesian space"
puts "New size: #{s.size}"
puts "Clear condition #0"
s.cond(:unset, index: 0)
puts "Clear all conditions"
s.cond(:clear)
puts "Restored size without conditions: #{s.size}"



# PRINT

puts "\nPrint Cartesian space as plain table, all functions included"
s.output
puts "\nPrint Cartesian space as Markdown"
s.output(format: :markdown)
puts "\nPrint Cartesian space as CSV"
s.output(format: :csv)



# IMPORT / EXPORT

puts "\nImport Cartesian space from JSON (similar method for YAML)"
File.write('example.json', JSON.pretty_generate(example))
puts "\nNote: after import, all assigned functions will calculate again, and they appear in the output"
s.import('example.json').output
puts "\nExport Cartesian space to YAML (similar method for JSON)"
s.export('example.yaml', format: :yaml)



# UTILITIES

puts "\nGet number of Cartesian combinations"
puts "Note: .size counts only dimensions, it ignores virtual constructs (functions, conditions, etc.)"
puts "Total size of Cartesian space: #{s.size}"
puts "\nPartially converting Cartesian space to array:"
array = s.to_a(limit: 3)
puts array.inspect
```

## Example

The most common use case for FlexCartesian is sweep analysis, that is, analysis of target value on all possible combinations of its parameters.
FlexCartesian has been designed to provide a concise form for sweep analysis:

```ruby
require 'flex-cartesian'

# create Cartesian space from JSON describing input parameters
s = FlexCartesian.new(path: './config.json')

# Define the values we want to calculate on all possible combinations of parameters
s.func(:add, :cmd) { |v| v.threads * v.batch }
s.func(:add, :performance) { |v| v.cmd / 3 }

# Calculate
s.func(:run)

# Save result as CSV, to easily open it in any business analytics tool
s.output(format: :csv, file: './benchmark.csv')
# For convenience, print result to the terminal
s.output
```

As this code is a little artificial, let us build real-world example.
Perhaps, we want to analyze PING perfomance from our machine to several DNS providers: Google DNS, CloudFlare DNS, and Cisco DNS.
For each of those services, we would like to know:

- What is our ping time?
- How does ping scale by packet size?
- How does ping statistics vary based on count of pings?

These input parameters form the following dimensions.

```json
{
  "count": [2, 4],
  "size": [32, 64],
  "target": [
    "8.8.8.8",           // Google DNS
    "1.1.1.1",           // Cloudflare DNS
    "208.67.222.222"     // Cisco OpenDNS
  ]
}
```

Note that `//` isn't officially supported by JSON, and you may want to remove the comments if you experience parser errors.
Let us build the code to run over these parameters.

```ruby
require 'flex-cartesian'

s = FlexCartesian.new(path: './ping_config.json') # file with the parameters as given above

result = {} # here we will store raw result of each ping and fetch target metrics from it

# this function shows actual ping command
s.func(:add, :command) do |v|
  "ping -c #{v.count} -s #{v.size} #{v.target}"
end

# this function gets raw result of actual ping command
s.func(:add, :raw_ping, hide: true) do |v|
  result[v.command] ||= `#{v.command} 2>&1`
end

# this function extracts ping time
s.func(:add, :time) do |v|
  if v.raw_ping =~ /min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/
    $1.to_f
  end
end

# this function extracts minimum ping time
s.func(:add, :min) do |v|
  if v.raw_ping =~ /min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/
    $1.to_f
  end
end

# funally, this function extracts losses of ping
s.func(:add, :loss) do |v|
  if v.raw_ping =~ /(\d+(?:\.\d+)?)% packet loss/
    $1.to_f
  end
end

# this is the spinal axis of FlexCartesian:
# calculate all functions on the entire Cartesian space of parameters aka dimensions
s.func(:run)

# save benchmark results to CSV for convenient analysis in BI tools
s.output(format: :csv, file: './benchmark.csv')

# for convenience, show tabular result on screen as well
s.output(colorize: true)
```

If you run the code, after a while it will generate benchmark results on the screen:

![Ping Benchmark Example](doc/ping_benchmark_example.png)

Additionally, CSV version of this result is saved as `./benchmark.csv`

The PING benchmarking code above is 100% practical and illustrative.
You can modify it and benchmark virtually anything:

- Local block devices using `dd`
- GPU-to-Storage connection using `gdsio`
- Local file systems using FS-based utilities
- Local CPU RAM using RAM disk or specialized benchmarks for CPU RAM
- Database performance using SQL client or non-SQL client utilities
- Performance of object storage of cloud providers, be it AWS S3, OCI Object Storage, or anything else
- Performance of any AI model, from simplistic YOLO to heavy-weight LLM such as LLAMA, Cohere, or DeepSeek
- ... Any other target application or service

In any use case, FlexCartesian will unfold complete landscape of the target performance over all configurable parameters.
As result, you will be able to spot optimal configurations, correlations, bottlenecks, and sweet spots.
Moreover, you will make your conclusions in a justifiable way.

Here is example of using FlexCartesian for [performance/cost analysis of YOLO](https://www.linkedin.com/pulse/comparing-gpu-a10-ampere-a1-shapes-object-oci-yuri-rassokhin-rseqf).



## API Overview

### Initialization
```ruby
FlexCartesian.new(dimensions = nil, path: nil, format: :json)
```
- `dimensions_hash`: optional hash with named dimensions; each value can be an `Enumerable` (arrays, ranges, etc)
- `path`: optional path to file with stored dimensions, JSON and YAML supported
- `format`: optional format of `path` file, defaults to JSON

Example:
```ruby
dimensions = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}

FlexCartesian.new(dimensions)
```

---

### Iterate Over All Combinations

Example:
```ruby
# With block
cartesian(dims = nil, lazy: false) { |vector| ... }
# Without block: returns Enumerator
cartesian(dims = nil, lazy: false)
```
- `dims`: optional dimensions hash (default is the one provided at initialization).
- `lazy`: if true, returns a lazy enumerator.

Each combination is passed as a `Struct` with fields matching the dimension names:
```ruby
s.cartesian { |v| puts "#{v.dim1} - #{v.dim2}" }
```

---

### Handling Functions
```ruby
func(command = :print, name = nil, hide: false, &block)
```
- `command`: symbol, one of the following
  - `:add` to add function as a virtual dimension to Cartesian space
  - `:del` to delete function from Cartesian space
  - `:print` as defaut action, prints all the functions added to Cartesian space
  - `:run` to calculate all the functions defined for Cartesian space
- `name`: symbol, name of the virtual dimension, e.g. `:my_function`
- `hide`: flag that hides or shows the function in .output; it is useful to hide intermediate calculations
- `block`: a function that receives each vector and returns a computed value

Functions show up in `.output` like additional (virtual) dimensions.

> Note: functions must be calculated excpliticy using `:run` command.
> Before the first calculation, a function has `nil` values in `.output`.
> Explicit :run is reequired to unambigously control points in the execution flow where high computational resource is to be consumed.
> Otherwise, automated recalculation of functions, perhaps, during `.output` would be a difficult-to-track computational burden.

Example:
```ruby
s = FlexCartesian.new( { dim1: [1, 2], dim2: ['A', 'B'] } )
s.func(:add, :increment) { |v| v.dim1 + 1 }

s.output(format: :markdown)
# | dim1 | dim2 | increment |
# |------|------|--------|
# | 1    | "A"  | 2    |
# | 1    | "B"  | 2    |
# ...
```


---

### Count Total Combinations
```ruby
size(dims = nil) → Integer
```
Returns the number of possible combinations.

---

### Convert to Array
```ruby
to_a(limit: nil) → Array
```
- `limit`: maximum number of combinations to collect.

---

### Iterate with Progress Bar
```ruby
progress_each(dims = nil, lazy: false, title: "Processing") { |v| ... }
```
Displays a progress bar using `ruby-progressbar`.

---

### Print Cartesian
```ruby
output(separator: " | ", colorize: false, align: true, format: :plain, limit: nil, file: nil)
- `separator`: how to visually separate columns in the output
- `colorize`: whether to colorize output or not
- `align`: whether to align output by column or not
- `format`: one of `:plain`, `:markdown`, or `:csv`
- `limit`: break the output after the first `limit` Cartesian combinations
- `file`: print to `file`
```

Prints all combinations in table form (plain/markdown/CSV).  
Markdown example:
```
| dim1 | dim2 |
|------|------|
|  1   | "a"  |
|  2   | "b"  |
```

---

### Import from JSON or YAML
```ruby
import(path, format: :json)
- `path`: input file
- `format`: format to read, `:json` and `:yaml` supported
```

Obsolete import methods:
```ruby
s.from_json("file.json")
s.from_yaml("file.yaml")
```

---

### Export to JSON or YAML
```ruby
export(path, format: :json)
- `path`: output file
- `format`: format to export, `:json` and `:yaml` supported
```

### Conditions on Cartesian Space
```ruby
cond(command = :print, index: nil, &block)
```
- `command`: one of the following
  - `:set` to set the condition to Cartesian space
  - `:unset` to remove the `index` condition from Cartesian space
  - `:clear` to remove all conditions from Cartesian space
  - `:print` default command, prints all the conditions on the Cartesian space
- `index`: index of the condition set to Cartesian space, it is used to remove specified condition
- `block`: definition of the condition, it should return `true` or `false` to avoid unpredictable behavior

Example:
```ruby
s.cond(:set) { |v| v.dim1 > v.dim3 }
s.cond # defaults to s.cond(:print) and shows all the conditions in the form 'index | definition'
s.cond(:unset, 0) # remove the condition
s.cond(:clear) # remove all conditions, if any
```



## License

This project is licensed under the terms of the GNU General Public License v3.0.  
See [LICENSE](LICENSE) for more details.
