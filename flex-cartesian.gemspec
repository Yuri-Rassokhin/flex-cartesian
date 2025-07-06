Gem::Specification.new do |spec|
  spec.name          = "flex-cartesian"
  spec.version       = "0.1.0"
  spec.authors       = ["Yury Rassokhin"]
  spec.email         = ["yuri.rassokhin@gmail.com"]

  spec.summary       = "Flexible and human-friendly Cartesian product enumerator for Ruby"
  spec.description   = "Supports dimension-agnostic iteration, named dimensions, structured output, lazy/eager evaluation, progress bar, JSON/YAML loading, and export to Markdown/CSV."

  spec.homepage      = "https://github.com/Yuri-Rassokhin/flex-cartesian"
  spec.license       = "GPL-3.0"

  spec.files         = Dir["lib/**/*.rb"] + %w[README.md LICENSE Gemfile]
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "ruby-progressbar", "~> 1.13"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "yaml"

  spec.metadata["source_code_uri"] = spec.homepage
end
