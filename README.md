# FlexCartesian

**Ruby implementation of flexible and human-friendly operations on Cartesian products.**  

---

## Features

✅ Named dimensions with arbitrary keys

✅ Enumerate over Cartesian product with a single block argument  

✅ Functions over Cartesian vectors are decoupled from dimensionality

✅ Calculate over dimensions using `.dim1 + .dim2` syntax in the block  

✅ Lazy and eager evaluation

✅ Progress bars for large Cartesian combinations  

✅ Export of Cartesian space to Markdown or CSV  

✅ Import of dimension space from JSON or YAML  

✅ Structured and colorized terminal output  

---

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

---

## Usage

```ruby
require 'flex-cartesian'

# Define a Cartesian space with named dimensions:
s = FlexCartesian.new({
  dim1: [1, 2],
  dim2: ['x', 'y'],
  dim3: [true, false]
})

# Iterate over all combinations and calculate a function on each combination:
s.cartesian do |v|
  puts "#{v.dim1}-#{v.dim2}" if v.dim3
end

# Get number of Cartesian combinations:
puts "Total size: #{s.size}"

# Convert Cartesian space to array of combinations
array = s.to_a(limit: 3)
puts array.inspect

# Display progress bar (useful for large Cartesian spaces)
s.progress_each do |v|
  do_something(v)
end

# Print Cartesian space as table
s.output(align: true)

# Lazy evaluation
s.cartesian(lazy: true).take(2).each { |v| puts v.inspect }

# Load from JSON or YAML
s = FlexCartesian.from_json("path/to/config.json")
s.output
```

---

## JSON/YAML input example

**config.json**
```json
{
  "dim1": [1, 2],
  "dim2": ["x", "y"],
  "dim3": [true, false]
}
```

**config.yml**
```yaml
dim1:
  - 1
  - 2
dim2:
  - x
  - y
dim3:
  - true
  - false
```

---

## Export output

```ruby
# Export to Markdown
s.output(format: :markdown, align: true)

# Export to CSV
s.output(format: :csv)
```

---

## License

This project is licensed under the terms of the GNU General Public License v3.0.  
See [LICENSE](LICENSE) for more details.
