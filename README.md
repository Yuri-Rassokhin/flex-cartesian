# FlexCartesian

**Ruby implementation of flexible and human-friendly operations on Cartesian products**  

## Features

✅ Named dimensions with arbitrary keys

✅ Enumerate over Cartesian product with a single block argument  

✅ Functions over Cartesian vectors are decoupled from dimensionality

✅ Calculate over named dimensions using `s.cartesian { |v| puts "#{v.dim1} and #{v.dim2}" }` syntax

✅ Add calculated functions over dimensions using `s.add_function { |v| v.dim1 + v.dim2 }`

✅ Lazy and eager evaluation

✅ Progress bars for large Cartesian combinations  

✅ Export of Cartesian space to Markdown or CSV  

✅ Import of dimension space from JSON or YAML  

✅ Structured and colorized terminal output  

## Installation

```bash
bundle install
gem build flex-cartesian.gemspec
gem install flex-cartesian-*.gem
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

# Add calculated function:
s.add_function(:increment) { |v| v.dim1 + 1 }

# Convert Cartesian space to array of combinations
array = s.to_a(limit: 3)
puts array.inspect

def do_something(v)
end

# Display progress bar (useful for large Cartesian spaces)
s.progress_each { |v| do_something(v) }

# Add calculated functions
s.add_function(:function1) { |v| v.dim1*3 }
s.add_function(:function2) { |v| v.dim1-1 }

# Print Cartesian space as table
s.output(align: true)

# Lazy evaluation without materializing entire Cartesian product in memory:
s.cartesian(lazy: true).take(2).each { |v| puts v.inspect }

# Load from JSON or YAML
File.write('example.json', JSON.pretty_generate(example))
s = FlexCartesian.from_json('example.json')
s.output

# Export to Markdown
s.output(format: :markdown, align: true)

# Export to CSV
s.output(format: :csv)
```

## API Overview

### Initialization
```ruby
FlexCartesian.new(dimensions_hash)
```
- `dimensions_hash`: a hash with named dimensions; each value can be an `Enumerable` (e.g., arrays, ranges).

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

### Add Calculated Functions
```ruby
add_function(name, &block)
```
- `name`: symbol — the name of the virtual dimension (e.g. `:label`)
- `block`: a function that receives each vector and returns a computed value

Calculated functions show up in `.output` like additional (virtual) dimensions.

Example:
```ruby
s = FlexCartesian.new( { dim1: [1, 2], dim2: ['A', 'B'] } )
s.add_function(:increment) { |v| v.dim1 + 1 }

s.output(format: :markdown)
# | dim1 | dim2 | increment |
# |------|------|--------|
# | 1    | "A"  | 2    |
# | 1    | "B"  | 2    |
# ...
```

> Note: Calculated functions are virtual — they are not part of the base dimensions, but they integrate seamlessly in output.

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

### Print Table to Console
```ruby
output(
  separator: " | ",
  colorize: false,
  align: false,
  format: :plain  # or :markdown, :csv
  limit: nil
)
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

### Load from JSON or YAML
```ruby
FlexCartesian.from_json("file.json")
FlexCartesian.from_yaml("file.yaml")
```

---

### Output from Vectors
Each yielded combination is a `Struct` extended with:
```ruby
output(separator: " | ", colorize: false, align: false)
```
Example:
```ruby
s.cartesian { |v| v.output(colorize: true, align: true) }
```

## License

This project is licensed under the terms of the GNU General Public License v3.0.  
See [LICENSE](LICENSE) for more details.
