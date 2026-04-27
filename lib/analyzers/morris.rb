class Morris < Analyzer

  Edge = Struct.new(:from_idx, :to_idx, :factor, :step)

  attr_reader :trajectories, :step, :seed, :edges

  def initialize(fc, trajectories:, step: 0.1, seed: nil)
    super(fc)

    @trajectories = trajectories
    @step         = step
    @seed         = seed
    @rng          = seed ? Random.new(seed) : Random.new
    @points = []
    @edges  = []
    @analysis = nil

    validate_trajectories!
    validate_step!
    build!
  end

def analyze(func:)
  effects = Hash.new { |h, k| h[k] = [] }

  @edges.each do |edge|
    from_v = @points[edge.from_idx]
    to_v   = @points[edge.to_idx]

    from_res = indexed_results[vector_key(from_v)]
    to_res   = indexed_results[vector_key(to_v)]

    next unless from_res && to_res

    y1 = from_res[func]
    y2 = to_res[func]

    next if y1.nil? || y2.nil?

    ee = (y2 - y1).to_f / edge.step
    effects[edge.factor] << ee
  end

  # Iterate over names to consider constant parameters -
  # the ones that has had no effect whatsoever
res = names.map do |name|
    factor = name
    ees = effects[factor]
    n = ees.size

    if n == 0
      {
        parameter: factor.to_s,
        "influence[#{func}]": 0.0,
        deviation: 0.0,
        probes: 0
      }
    else
      mean = ees.sum / n.to_f
      importance = ees.map(&:abs).sum / n.to_f

      variance =
        if n > 1
          ees.map { |e| (e - mean)**2 }.sum / (n - 1).to_f
        else
          0.0
        end

      deviation = Math.sqrt(variance)

      {
        parameter: factor.to_s,
        "influence[#{func}]": importance.round(2),
        deviation: deviation.round(2),
        probes: n
      }
    end
  end.compact.sort_by { |row| -row[:"influence[#{func}]"] }
  @analysis = res
  res
end

def categorize(rows, function:)
  return rows if rows.nil? || rows.empty?

  # Calculate general deviation of the target function, Y_max - Y_min
  # Gather all the results for this function from cash
  all_y_values = indexed_results.values.map { |r| r[function] }.compact
  
  y_range = if all_y_values.empty?
              1.0 # Protection from division by zero, if no data
            else
              max_y = all_y_values.max
              min_y = all_y_values.min
              range = max_y - min_y
              range.zero? ? 1.0 : range # Protection from constant function
            end

  rows.map do |row|
    imp   = row[:"influence[#{function}]"]
    sigma = row[:deviation]

    # Categorization of the influence is RELATIVE to the general deviation of the function
    influence_ratio = imp / y_range.to_f
    strength =
      if influence_ratio >= 0.10      # adds >= 10% of the deviation
        "strong"
      elsif influence_ratio >= 0.02   # 2% to 10%
        "moderate"
      else                            # less than 2%
        "negligible"
      end

    # Categorization of linearity (sigma / mu)
    linearity = "undefined"
    
    # If the parameter is neglifible, there's no point in calculating its linearity
    if strength != "negligible" && imp > 0
      ratio = sigma / imp
      linearity =
        if ratio < 0.5
          "linear"
        elsif ratio <= 1.0
          "non-linear"
        else
          "highly non-linear"
        end
    end

    row.merge(category: strength, linearity: linearity)
  end
end

def recommend(rows, function:)
  return rows if rows.nil? || rows.empty?

  rows.map do |row|
    recommendation =
      case [row[:category], row[:linearity]]
      when ["strong", "linear"]
        "direct and predictable impact; prime candidate for gradient-based optimization"
      when ["strong", "highly non-linear"]
        "critical parameter with complex interactions; prioritize for variance-based analysis (e.g. Sobol)"
      when ["strong", "non-linear"]
        "important parameter; ensure sufficient grid density around expected operating zones"
      when ["moderate", "linear"], ["moderate", "non-linear"], ["moderate", "highly non-linear"]
        "secondary priority; fine-tune only after optimizing 'strong' parameters"
      when ["negligible", "undefined"]
        "fix at default or cheapest value to reduce dimensionality"
      else
        "review parameter configuration"
      end
    
    row.merge(recommendation: recommendation)
  end
end

  def output(func:, categorize: true, recommend: true, **opts)
    raise ArgumentError, "target function must be provided" unless func
    raise "Cannot execute #sensitivity as there are no functions defined in parameter space" if @space.derived.empty?
    rows = @analysis.nil? ? analyze(func: func) : @analysis
    rows = self.categorize(rows, function: func) if categorize
    rows = self.recommend(rows, function: func) if recommend
    @space.output(rows, **opts)
  end

def card
  @name = "Morris sensitivity analysis"
  @description = "Morris method explores the parameter space by changing one parameter at a time across multiple trajectories, and quantifies rate and linearity of its influence on the target function"
  @complexity = "O( dimensions · trajectories )"
  @category = "Sensitivity analysis"
  @url = "https://en.wikipedia.org/wiki/Morris_method"
end

private

  # Dynamic calculation of the stride in terms of the index for a given parameter
  def index_step_for(dim_idx)
    levels_count = levels[dim_idx].size
    # Edge case: constant parameter ==> stride = 0
    return 0 if levels_count <= 1

    # Amount of available hops (note the edges of the space as well as space conditions, if any
    intervals = levels_count - 1

    # Relative nature of the stride: number of indices as a percentage (@step)
    calculated_step = (intervals * @step).round

    # The stride must be >= 1, otherwise we get stuck,
    # but not exceeding the maximum amount of intervals 
    [[calculated_step, 1].max, intervals].min
  end

  def vector_key(v)
    names.map { |name| v.send(name) }
  end

  def indexed_results
    @indexed_results ||= begin
      h = {}
      results.each do |point, row|
        h[vector_key(point)] = row
      end
      h
    end
  end

  def build!
    @trajectories.times do
      build_trajectory!
    end
  end

  def build_trajectory!
    current_indices = random_start_indices
    from_idx = add_point(current_indices)
    return unless from_idx

    # We only pick those parameters that have enough dimensional values to take at least one step (that is, >= 2 values)
    active_factors = (0...names.size).select { |i| index_step_for(i) > 0 }
    factor_order = active_factors.shuffle(random: @rng)

    factor_order.each do |factor_idx|
      next_indices = current_indices.dup

      # Finally, we get individual discrete stride 
      step_size = index_step_for(factor_idx)
      next_indices[factor_idx] += step_size

      to_idx = add_point(next_indices)
      next unless to_idx

      # DETERMINE RELATIVE DELTA: how much of the entire range has been passed
      # This value will form the denominator in the calculation of the elementary effect
      intervals = levels[factor_idx].size - 1
      relative_delta = step_size.to_f / intervals

      @edges << Edge.new(
        from_idx: from_idx,
        to_idx: to_idx,
        factor: names[factor_idx],
        step: relative_delta # We store % of the shirt, NOT indices 
      )

      current_indices = next_indices
      from_idx = to_idx
    end
  end

  def add_point(level_indices)
    values = level_indices.each_with_index.map do |level_idx, dim_idx|
      levels[dim_idx][level_idx]
    end

    point = @struct.new(*values)
    return nil unless space.valid?(point)

    @points << point
    @points.size - 1
  end

  def random_start_indices
    levels.each_with_index.map do |factor_levels, dim_idx|
      step_size = index_step_for(dim_idx)
      max_start = factor_levels.size - 1 - step_size

      if max_start < 0 || step_size == 0
        # If the parameter is constart, and we can't take a step,
        # We just take random value
        @rng.rand(0...factor_levels.size)
      else
        @rng.rand(0..max_start)
      end
    end
  end

  def validate_step!
    # Now the step is % (thus, 0.1 stands for 10%)
    unless @step.is_a?(Numeric) && @step > 0 && @step <= 1
      raise ArgumentError, "step must be a relative float between 0.0 and 1.0 (e.g., 0.1 for 10%)"
    end
  end

  def validate_trajectories!
    unless @trajectories.is_a?(Integer) && @trajectories > 0
      raise ArgumentError, "trajectories must be a positive integer"
    end
  end

end



