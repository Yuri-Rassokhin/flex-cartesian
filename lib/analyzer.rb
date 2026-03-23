class Analyzer

  attr_reader :fc

  def initialize(fc)
    @fc = fc

    unless fc.respond_to?(:function_results) && fc.function_results
      raise ArgumentError, "FlexCartesian has no computed results. Run func(:run) first."
    end
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
    raise NotImplementedError, "#{self.class} must implement #sensitivity"
  end

  def output(function:, **opts)
    rows = sensitivity(function: function)
    @fc.table(rows, **opts)
  end

end
