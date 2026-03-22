module FlexCartesianPlan

  def plan(type = nil, **opts)
    @plan =
      case type
      when nil, :cartesian
        nil
      when :morris
        require 'plans/morris'
        Morris.new(dimensions: @dimensions, **opts)
      else
        raise ArgumentError, "Unknown plan type: #{type.inspect}"
      end

    self
  end

  def sensitivity(function:, recommend: false, **opts)
    raise "No active plan" unless @plan
    rows = @plan.sensitivity(results: @function_results, function: function)
    rows = @plan.recommend(rows, function: function) if recommend
    table(rows, **opts)
  end

end

