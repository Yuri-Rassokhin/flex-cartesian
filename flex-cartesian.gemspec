require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "flex-cartesian"
  spec.version       = FlexCartesian::VERSION
  spec.authors       = ["Yury Rassokhin"]
  spec.email         = ["yuri.rassokhin@gmail.com"]

  spec.summary       = "Operations on Cartesian product for Ruby"
  spec.description   = "Operations on Cartesian product for Ruby. Provides user-defined functions and conditions; DoE (design of experiment) methods such as assessment of the influence of Cartesian parameters on the target function; dimensionality-agnostic and dimensionality-aware iterators; named dimensions; tabular output; lazy/eager evaluation; progress bar; import from JSON/YAML; export to Markdown/CSV. Code example: https://github.com/Yuri-Rassokhin/flex-cartesian/blob/main/README.md#example"
  spec.homepage      = "https://github.com/Yuri-Rassokhin/flex-cartesian"
  spec.license       = "GPL-3.0-only"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE Gemfile CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "progressbar", "~> 1.13"
  spec.add_dependency "method_source", "~> 1.0"
  spec.add_dependency "csv"

  spec.required_ruby_version = '>= 3.0'

  spec.metadata["source_code_uri"] = spec.homepage
end
