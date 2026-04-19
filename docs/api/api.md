block-beta
  columns 1

  A["Analyzers
  ----------------
  Morris
  def initialize
  def sensitivity
  def output"]

  B["Core Components"]
  block:C:5
    DS["Data Sources
    def data"]
    UT["Utilities
    def size
    def to_a
    def vector_to"]
    FN["Functions
    def func"]
    IT["Iterators
    def cartesian"]
    IO["Input / Output
    def import
    def export
    def visualize..."]
  end

  D["Conditions
  ----------------
  def cond"]

  E["Parameter Space
  ----------------
  def initialize
  valid?
  levels
  dimensionality..."]

  A --> B
  B --> D
  D --> E
