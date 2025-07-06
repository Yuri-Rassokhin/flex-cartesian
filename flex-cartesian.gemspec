Gem::Specification.new do |spec|
  spec.name          = "flex-cartesian"
  spec.version       = "0.1.8"
  spec.authors       = ["Yury Rassokhin"]
  spec.email         = ["yuri.rassokhin@gmail.com"]

  spec.summary       = "Flexible and human-friendly Cartesian product enumerator for Ruby"
  spec.description   = "Flexible and human-friendly Cartesian product enumerator for Ruby. Supports calculated functions, dimension-agnostic iterators, named dimensions, tabular output, lazy/eager evaluation, progress bar, JSON/YAML loading, and export to Markdown/CSV. Code example: https://github.com/Yuri-Rassokhin/flex-cartesian/blob/main/README.md#usage"
  spec.homepage      = "https://github.com/Yuri-Rassokhin/flex-cartesian"
  spec.license       = "GPL-3.0"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE Gemfile CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "ruby-progressbar", "~> 1.13"
  spec.add_dependency "json", "~> 2.0"

  spec.metadata["source_code_uri"] = spec.homepage
end
