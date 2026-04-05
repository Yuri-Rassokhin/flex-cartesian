class Analyzer

  attr_reader :space, :names, :levels
  attr_reader :name, :description, :url, :complexity, :category

  def initialize(space)
    @space = space
    @struct = @space.struct
    card
  end

  def card
    raise NotImplementedError, "#{self.class} must implement #card"
  end

  def results
    @space.function_results
  end

  def dimensions
    @space.dimensions
  end

  def names
    @space.names
  end

  def levels
    @space.levels
  end

  def cartesian(&blk)
    @space.cartesian(&blk)
  end

  def output
    raise "Method must be implemented in a child class"
  end
#  def sensitivity(function:, **opts)
#    rows = sensitivity(function: function)
#    @space.output(rows, **opts)
#  end

end
