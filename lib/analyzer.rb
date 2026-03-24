class Analyzer

  attr_reader :fc

  def initialize(fc)
    @fc = fc

    @name = nil
    @description = nil
    @url = nil
  end

  def card
    raise NotImplementedError, "#{self.class} must implement #card"
  end

  def results
    @fc.function_results
  end

  def dimensions
    @fc.dimensions
  end

  def each_point(&blk)
    return enum_for(:each_point) unless block_given?
    @fc.cartesian(&blk)  # already condition-aware
  end

  def sensitivity(function:)
    raise ArgumentError, "target function must be provided" unless function
    raise "Cannot execute #sensitivity as there are no functions defined in parameter space" if @fc.derived.empty?
  end

  def output(function:, **opts)
    rows = sensitivity(function: function)
    @fc.table(rows, **opts)
  end

end
