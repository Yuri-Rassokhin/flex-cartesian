Gem::Specification.new do |spec|
  spec.name          = "flex-cartesian"
  spec.version       = "1.3.0"
  spec.authors       = ["Yury Rassokhin"]
  spec.email         = ["yuri.rassokhin@gmail.com"]

  spec.summary       = "Flexible and human-friendly Cartesian product enumerator for Ruby"
  spec.description   = "Flexible and human-friendly Cartesian product enumerator for Ruby. Supports functions and conditions on cartesian, dimensionality-agnostic/dimensionality-aware iterators, named dimensions, tabular output, lazy/eager evaluation, progress bar, import from JSON/YAML, and export to Markdown/CSV. Code example: https://github.com/Yuri-Rassokhin/flex-cartesian/blob/main/README.md#example"
  spec.homepage      = "https://github.com/Yuri-Rassokhin/flex-cartesian"
  spec.license       = "GPL-3.0"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE Gemfile CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "ruby-progressbar", "~> 1.13"
  spec.add_dependency "progressbar", "~> 1.13"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "method_source", "~> 1.0"

  spec.required_ruby_version = '>= 3.0'

  spec.metadata["source_code_uri"] = spec.homepage
end
