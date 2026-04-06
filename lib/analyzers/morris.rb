class Morris < Analyzer

  Edge = Struct.new(:from_idx, :to_idx, :factor, :step)

  attr_reader :trajectories, :step, :seed, :edges

  def initialize(fc, trajectories:, step: 1, seed: nil)
    super(fc)

    @trajectories = trajectories
    @step         = step
    @seed         = seed
    @rng          = seed ? Random.new(seed) : Random.new
    @points = []
    @edges  = []

    validate_trajectories!
    validate_step!
    build!
  end

def sensitivity(function:)
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

  # Итерируемся по names, чтобы учесть константные параметры, 
  # для которых не было вычислено ни одного эффекта
  names.map do |name|
    factor = name
    ees = effects[factor]
    n = ees.size

    if n == 0
      {
        parameter: factor.to_s,
        "influence[#{function}]": 0.0,
        nonlinearity: 0.0,
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

      nonlinearity = Math.sqrt(variance)

      {
        parameter: factor.to_s,
        "influence[#{function}]": importance.round(2),
        nonlinearity: nonlinearity.round(2),
        probes: n
      }
    end
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
            { strength: "strong", linearity: "nonlinear" }
          else
            { strength: "strong", linearity: "linear" }
          end
        elsif imp <= threshold_low
          { strength: "negligible", linearity: "undefined" }
        else
          { strength: "moderate", linearity: "undefined" }
        end

      row.merge( category: category[:strength], linearity: category[:linearity] )
    end
  end

  def recommend(rows, function:)
    return rows if rows.nil? || rows.empty?

    rows.map do |row|
      recommendation =
        if row[:category] == "strong" and row[:linearity] == "linear"
          "pick a few pivotal values to reduce computations"
        elsif row[:category] == "strong" and row[:linearity] == "nonlinear"
          "enhance granularity and coverage to explore all phase transitions"
        elsif row[:category] == "negligible"
          "fix any value to reduce dimensiality"
        else
          "further exploration with more aggressive Morris parameters and finer granularity may be required"
        end
      row.merge(recommendation: recommendation)
    end
  end

  def output(function:, categorize: true, recommend: true, **opts)
    raise ArgumentError, "target function must be provided" unless function
    raise "Cannot execute #sensitivity as there are no functions defined in parameter space" if @space.derived.empty?
    rows = sensitivity(function: function)
    rows = self.categorize(rows, function: function) if categorize
    rows = self.recommend(rows, function: function) if recommend
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

  # Метод для динамического расчета шага в индексах для конкретного параметра
  def index_step_for(dim_idx)
    levels_count = levels[dim_idx].size
    # Если параметр константный (одно значение) - шаг равен 0
    return 0 if levels_count <= 1

    # Количество доступных интервалов (прыжков)
    intervals = levels_count - 1

    # Считаем количество индексов для шага на основе процента (@step)
    calculated_step = (intervals * @step).round

    # Шаг должен быть минимум 1 (иначе стоим на месте),
    # но не больше максимального количества интервалов
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

    # Берем только те параметры, у которых достаточно значений для шага (хотя бы 2 значения)
    active_factors = (0...names.size).select { |i| index_step_for(i) > 0 }
    factor_order = active_factors.shuffle(random: @rng)

    factor_order.each do |factor_idx|
      next_indices = current_indices.dup

      # Получаем индивидуальный дискретный шаг для текущего фактора
      step_size = index_step_for(factor_idx)
      next_indices[factor_idx] += step_size

      to_idx = add_point(next_indices)
      next unless to_idx

      # СЧИТАЕМ ОТНОСИТЕЛЬНУЮ ДЕЛЬТУ: какая доля от всего диапазона была пройдена.
      # Именно это значение пойдет в знаменатель при расчете элементарного эффекта.
      intervals = levels[factor_idx].size - 1
      relative_delta = step_size.to_f / intervals

      @edges << Edge.new(
        from_idx: from_idx,
        to_idx: to_idx,
        factor: names[factor_idx],
        step: relative_delta # Сохраняем % сдвига, а не индексы
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
        # Если не можем сделать шаг (или параметр константа) -
        # берем случайное доступное значение
        @rng.rand(0...factor_levels.size)
      else
        @rng.rand(0..max_start)
      end
    end
  end

  def validate_step!
    # Теперь step - это процент (например, 0.1 для 10%)
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



