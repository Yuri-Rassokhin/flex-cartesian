
class Morris < Plan
  Edge = Struct.new(:from_idx, :to_idx, :factor, :step, keyword_init: true)

  attr_reader :dimensions, :names, :levels, :trajectories, :step, :seed, :edges

  def initialize(dimensions:, trajectories:, step: 1, seed: nil)
    @dimensions   = dimensions
    @trajectories = trajectories
    @step         = step
    @seed         = seed
    @rng          = seed ? Random.new(seed) : Random.new

    validate_dimensions!
    validate_step!
    validate_trajectories!

    @names  = @dimensions.keys
    @levels = @names.map { |name| normalize_levels(@dimensions[name]) }

    @struct_class = Struct.new(*@names).tap { |sc| sc.include(FlexOutput) }

    @points = []
    @edges  = []

    build!
  end

  def each_point(&blk)
    return @points.to_enum unless block_given?
    @points.each(&blk)
  end

  def size
    @points.size
  end

  def analysis_type
    :morris
  end

  def metadata
    {
      trajectories: @trajectories,
      step: @step,
      seed: @seed,
      factors: @names
    }
  end

  def point(idx)
    @points[idx]
  end

def analyze(results:, metric:)
  raise ArgumentError, "metric must be provided" unless metric

  effects = Hash.new { |h, k| h[k] = [] }

  @edges.each do |edge|
    from_v = @points[edge.from_idx]
    to_v   = @points[edge.to_idx]

    from_res = results[from_v]
    to_res   = results[to_v]

    next unless from_res && to_res

    y1 = from_res[metric]
    y2 = to_res[metric]

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
      parameter: factor,
      importance: importance.round(2),
      nonlinearity: nonlinearity.round(2),
#      mean: mean.round(2), # not so much informative
      probes: n
    }
  end.compact.sort_by { |row| -row[:importance] }
end

  private

  def build!
    @trajectories.times do
      build_trajectory!
    end
  end

  def build_trajectory!
    current_indices = random_start_indices
    from_idx = add_point(current_indices)

    factor_order = (0...@names.size).to_a.shuffle(random: @rng)

    factor_order.each do |factor_idx|
      next_indices = current_indices.dup
      next_indices[factor_idx] += @step

      to_idx = add_point(next_indices)

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
    @points << point
    @points.size - 1
  end

  def random_start_indices
    @levels.map do |factor_levels|
      max_start = factor_levels.size - 1 - @step
      @rng.rand(0..max_start)
    end
  end

  def normalize_levels(value)
    value.is_a?(Enumerable) ? value.to_a : [value]
  end

  def validate_dimensions!
    unless @dimensions.is_a?(Hash) && !@dimensions.empty?
      raise ArgumentError, "dimensions must be a non-empty Hash"
    end
  end

  def validate_step!
    unless @step.is_a?(Integer) && @step > 0
      raise ArgumentError, "step must be a positive integer"
    end
  end

  def validate_trajectories!
    unless @trajectories.is_a?(Integer) && @trajectories > 0
      raise ArgumentError, "trajectories must be a positive integer"
    end
  end

end

