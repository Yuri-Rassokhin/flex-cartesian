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

  def sensitivity(function:)
    raise ArgumentError, "target function must be provided" unless function
    raise "Cannot execute #sensitivity as there are no functions defined in parameter space" if @space.derived.empty?
  end

  def output(function:, **opts)
    rows = sensitivity(function: function)
    @space.table(rows, **opts)
  end

end
