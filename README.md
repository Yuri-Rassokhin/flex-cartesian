# FlexCartesian

**Ruby implementation of flexible and human-friendly operations on Cartesian products**  

## Features

✅ Named dimensions with arbitrary keys

✅ Enumerate over Cartesian product with a single block argument  

✅ Functions over Cartesian vectors are decoupled from dimensionality

✅ Calculate over dimensions using `s.cartesian { |v| v.dim1 + v.dim2}` syntax

✅ Lazy and eager evaluation

✅ Progress bars for large Cartesian combinations  

✅ Export of Cartesian space to Markdown or CSV  

✅ Import of dimension space from JSON or YAML  

✅ Structured and colorized terminal output  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flex-cartesian'
```

And then execute:

```bash
bundle install
```

Or install it manually:

```bash
gem install flex-cartesian
```

## Usage

```ruby
require 'flex-cartesian'

# Define a Cartesian space with named dimensions:
example = {
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
}
s = FlexCartesian.new(example)

# Iterate over all combinations and calculate function on each combination:
s.cartesian { |v| puts "#{v.dim1}-#{v.dim2}" if v.dim3 }

# Get number of Cartesian combinations:
puts "Total size: #{s.size}"

# Convert Cartesian space to array of combinations
array = s.to_a(limit: 3)
puts array.inspect

# Display progress bar (useful for large Cartesian spaces)
s.progress_each { |v| do_something(v) }

# Print Cartesian space as table
s.output(align: true)

# Lazy evaluation without materializing entire Cartesian product in memory:
s.cartesian(lazy: true).take(2).each { |v| puts v.inspect }

# Load from JSON or YAML
File.write('example.json', JSON.pretty_generate(example))
s = FlexCartesian.from_json('exampe.json')
s.output

# Export to Markdown
s.output(format: :markdown, align: true)

# Export to CSV
s.output(format: :csv)
```

## License

This project is licensed under the terms of the GNU General Public License v3.0.  
See [LICENSE](LICENSE) for more details.
