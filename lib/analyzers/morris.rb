class Morris < Analyzer
  Edge = Struct.new(:from_idx, :to_idx, :factor, :step)

  attr_reader :trajectories, :step, :seed, :edges

  def initialize(fc, trajectories:, step: 0.1, seed: nil)
    super(fc)

    @trajectories = trajectories
    @step         = step
    @seed         = seed
    @rng          = seed ? Random.new(seed) : Random.new
    @points       = []
    @edges        = []
    @analysis     = nil

    validate_trajectories!
    validate_step!
    build!
  end

  def analyze(func:)
    effects = Hash.new { |h, k| h[k] = [] }

    @edges.each do |edge|
      from_v = @points[edge.from_idx]
      to_v   = @points[edge.to_idx]

      # Используем уже готовый хэш results из родительского контекста
      from_res = results[from_v]
      to_res   = results[to_v]

      next unless from_res && to_res

      y1 = from_res[func]
      y2 = to_res[func]

      next if y1.nil? || y2.nil?

      ee = (y2 - y1).to_f / edge.step
      effects[edge.factor] << ee
    end

    # Iterate over names to consider constant parameters -
    # the ones that has had no effect whatsoever
    res = names.map do |factor|
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

    # Берем значения напрямую из кэша results
    all_y_values = results.values.map { |r| r[function] }.compact

    y_range = if all_y_values.empty?
                1.0 # Protection from division by zero, if no data
              else
                range = all_y_values.max - all_y_values.min
                range.zero? ? 1.0 : range # Protection from constant function
              end

    rows.map do |row|
      imp   = row[:"influence[#{function}]"]
      sigma = row[:deviation]

      influence_ratio = imp / y_range.to_f
      strength =
        if influence_ratio >= 0.10      # adds >= 10% of the deviation
          "strong"
        elsif influence_ratio >= 0.02   # 2% to 10%
          "moderate"
        else                            # less than 2%
          "negligible"
        end

      linearity = "undefined"

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

  # Теперь обращаемся к dimensions напрямую по имени измерения
  def index_step_for(dimension_name)
    levels_count = dimensions[dimension_name].size
    return 0 if levels_count <= 1

    intervals = levels_count - 1
    calculated_step = (intervals * @step).round

    [[calculated_step, 1].max, intervals].min
  end

  def build!
    @trajectories.times do
      build_trajectory!
    end
  end

  def build_trajectory!
    # Начинаем сразу с вектора, а не с массива индексов
    current_v = random_start_point
    from_idx = add_point(current_v)
    return unless from_idx

    # Выбираем факторы, по которым возможен хотя бы один шаг
    active_factors = names.select { |dim| index_step_for(dim) > 0 }
    factor_order = active_factors.shuffle(random: @rng)

    factor_order.each do |factor|
      step_size = index_step_for(factor)

      # Делегируем сдвиг твоему методу: получаем новое значение для конкретного измерения
      new_dim_value = vector(command: :shift, vector: current_v, dimension: factor, offset: step_size)
      next if new_dim_value.nil?

      # Собираем новый вектор, заменяя значение только для текущего фактора
      next_values = names.map do |dim|
        dim == factor ? new_dim_value : current_v.public_send(dim)
      end
      next_v = @struct.new(*next_values)

      to_idx = add_point(next_v)
      next unless to_idx

      intervals = dimensions[factor].size - 1
      relative_delta = step_size.to_f / intervals

      @edges << Edge.new(
        from_idx: from_idx,
        to_idx: to_idx,
        factor: factor,
        step: relative_delta
      )

      current_v = next_v
      from_idx = to_idx
    end
  end

  # Формирует сразу готовый начальный вектор, а не индексы
  def random_start_point
    values = names.map do |dim|
      levels = dimensions[dim]
      step_size = index_step_for(dim)
      max_start = levels.size - 1 - step_size

      idx = if max_start < 0 || step_size == 0
              @rng.rand(0...levels.size)
            else
              @rng.rand(0..max_start)
            end
      levels[idx]
    end

    @struct.new(*values)
  end

  # Сохраняет вектор и возвращает его индекс в @points
  def add_point(point)
    return nil unless @space.valid?(point)

    @points << point
    @points.size - 1
  end

  def validate_step!
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
