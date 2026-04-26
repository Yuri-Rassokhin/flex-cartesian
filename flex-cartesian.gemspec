require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "flex-cartesian"
  spec.version       = FlexCartesian::VERSION
  spec.authors       = ["Yury Rassokhin"]
  spec.email         = ["yuri.rassokhin@gmail.com"]

  spec.summary       = "Parametric system analysis as operations on Cartesian product for Ruby"
  spec.description   = "A Ruby DSL for operations on Cartesian multidimensional spaces. Features user-defined functions, space conditions, dimensionality-agnostic and dimensionality-aware iterators; named dimensions; tabular output; lazy/eager evaluation; progress bar; import from JSON/YAML/CSV/XLSX; export to Markdown/CSV; DoE with Parametric Behaviour Blueprinting (PBB) to create blueprints of real systems; and visual heatmaps to model and optimize real systems effortlessly. Code examples: https://github.com/Yuri-Rassokhin/flex-cartesian/tree/main/examples/13_chatgpt_semantic_shift/example.rb"
  spec.homepage      = "https://github.com/Yuri-Rassokhin/flex-cartesian"
  spec.license       = "GPL-3.0-only"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE Gemfile CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "progressbar", "~> 1.13"
  spec.add_dependency "method_source", "~> 1.0"
  spec.add_dependency "csv"
  spec.add_dependency "roo"

  spec.required_ruby_version = '>= 3.0'

  spec.metadata["source_code_uri"] = spec.homepage
end
