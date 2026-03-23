class Morris < Analyzer
  Edge = Struct.new(:from_idx, :to_idx, :factor, :step, keyword_init: true)

  attr_reader :names, :levels, :trajectories, :step, :seed, :edges

  def initialize(fc, trajectories:, step: 1, seed: nil)
    super(fc)

    @trajectories = trajectories
    @step         = step
    @seed         = seed
    @rng          = seed ? Random.new(seed) : Random.new

    @names  = fc.raw_dimensions.keys
    @levels = @names.map { |name| normalize_levels(fc.raw_dimensions[name]) }

    validate_trajectories!
    validate_step!

    @struct_class = Struct.new(*@names).tap { |sc| sc.include(FlexOutput) }

    @points = []
    @edges  = []

    build!
  end

  def add_point(level_indices)
    values = level_indices.each_with_index.map do |level_idx, dim_idx|
      @levels[dim_idx][level_idx]
    end

    point = @struct_class.new(*values)

    return nil unless @fc.valid?(point)

    @points << point
    @points.size - 1
  end

  def build_trajectory!
    current_indices = random_start_indices
    from_idx = add_point(current_indices)
    return unless from_idx

    factor_order = (0...@names.size).to_a.shuffle(random: @rng)

    factor_order.each do |factor_idx|
      next_indices = current_indices.dup
      next_indices[factor_idx] += @step

      to_idx = add_point(next_indices)
      next unless to_idx

      @edges << Edge.new(
        from_idx: from_idx,
        to_idx: to_idx,
        factor: @names[factor_idx],
        step: @step
      )

      current_indices = next_indices
      from_idx = to_idx
    end
  end

def sensitivity(function:)
  raise ArgumentError, "target function must be provided" unless function

  effects = Hash.new { |h, k| h[k] = [] }

  @edges.each do |edge|
    from_v = @points[edge.from_idx]
    to_v   = @points[edge.to_idx]

    from_res = indexed_results[vector_key(from_v)]
    to_res   = indexed_results[vector_key(to_v)]

    next unless from_res && to_res

    y1 = from_res[function]
    y2 = to_res[function]

    next if y1.nil? || y2.nil?

    ee = (y2 - y1).to_f / edge.step
    effects[edge.factor] << ee
  end

  effects.map do |factor, ees|
    n = ees.size
    next if n == 0

    mean = ees.sum / n.to_f
    importance = ees.map(&:abs).sum / n.to_f

    variance =
      if n > 1
        ees.map { |e| (e - mean)**2 }.sum / (n - 1).to_f
      else
        0.0
      end

    nonlinearity = Math.sqrt(variance)

    {
      parameter: factor.to_s,
      "influence[#{function}]": importance.round(2),
      nonlinearity: nonlinearity.round(2),
      probes: n
    }
  end.compact.sort_by { |row| -row[:"influence[#{function}]"] }
end

  def categorize(rows, function:)
    return rows if rows.nil? || rows.empty?

    max_importance = rows.map { |r| r[:"influence[#{function}]"] }.max
    threshold_high = max_importance * 0.2
    threshold_low  = max_importance * 0.05

    rows.map do |row|
      imp   = row[:"influence[#{function}]"]
      sigma = row[:nonlinearity]

      category =
        if imp >= threshold_high
          if sigma > imp
            "Strong nonlinear influence"
          else
            "Strong linear influence"
          end
        elsif imp <= threshold_low
          "Negligible"
        else
          "Moderate influence"
        end

      row.merge(category: category)
    end
  end

  def recommend(rows, function:)
    return rows if rows.nil? || rows.empty?

    rows.map do |row|
      recommendation =
        case row[:category]
        when "Strong nonlinear influence"
          "Further investigation with full coverage"
        when "Strong linear influence"
          "Fix several pivotal values"
        when "Negligible"
          "Fix its value to reduce dimensionality"
        else
          "Further investigation may be required"
        end

      row.merge(recommendation: recommendation)
    end
  end

  def output(function:, categorize: true, recommend: true, **opts)
    rows = sensitivity(function: function)
    rows = self.categorize(rows, function: function) if categorize
    rows = self.recommend(rows, function: function) if recommend
    fc.table(rows, **opts)
  end

private

def vector_key(v)
  @names.map { |name| v.send(name) }
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

  factor_order = (0...@names.size).to_a.shuffle(random: @rng)

  factor_order.each do |factor_idx|
    next_indices = current_indices.dup
    next_indices[factor_idx] += @step

    to_idx = add_point(next_indices)
    next unless to_idx

    @edges << Edge.new(
      from_idx: from_idx,
      to_idx: to_idx,
      factor: @names[factor_idx],
      step: @step
    )

    current_indices = next_indices
    from_idx = to_idx
  end
end

def add_point(level_indices)
  values = level_indices.each_with_index.map do |level_idx, dim_idx|
    @levels[dim_idx][level_idx]
  end

  point = @struct_class.new(*values)
  return nil unless @fc.valid?(point)

  @points << point
  @points.size - 1
end

def random_start_indices
  @levels.map do |factor_levels|
    max_start = factor_levels.size - 1 - @step
    raise ArgumentError, "step=#{@step} is too large for factor with #{factor_levels.size} levels" if max_start < 0
    @rng.rand(0..max_start)
  end
end

def normalize_levels(value)
  value.is_a?(Enumerable) && !value.is_a?(String) ? value.to_a : [value]
end

def validate_step!
  unless @step.is_a?(Integer) && @step > 0
    raise ArgumentError, "step must be a positive integer"
  end

  min_levels = @levels.map(&:size).min
  if min_levels <= @step
    raise ArgumentError, "step=#{@step} is too large for dimensions with #{min_levels} levels"
  end
end

def validate_trajectories!
  unless @trajectories.is_a?(Integer) && @trajectories > 0
    raise ArgumentError, "trajectories must be a positive integer"
  end
end

end

