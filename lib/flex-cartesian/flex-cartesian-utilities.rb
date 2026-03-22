module FlexCartesianUtilities

def dimensions(data = @dimensions, raw: false, separator: ', ', dimensions: true, values: true, lazy: false)
  return nil if !dimensions && !values

  unless data.is_a?(Struct) || data.is_a?(Hash)
    raise ArgumentError, "Incorrect type of dimensions: #{data.class}"
  end

  if data.is_a?(Struct)
    return nil unless valid?(data)

    return data.each_pair.map { |k, val|
      (dimensions ? "#{k}" : "") +
      ((dimensions && values) ? "=" : "") +
      (values ? "#{val}" : "")
    }.join(separator)
  end

  enum = Enumerator.new do |y|
    cartesian(data, lazy: lazy) do |v|
      next unless valid?(v)
      y << dimensions(v, raw: raw, separator: separator, dimensions: dimensions, values: values, lazy: lazy)
    end
  end

  return enum if lazy
  enum.to_a.join("\n")
end

  # Return number of combinations in parameter space, with respect to conditions
  def size
    return 0 unless @dimensions.is_a?(Hash)

    return @plan.size if @plan

    if @conditions.empty?
      values = @dimensions.values.map { |dim| dim.is_a?(Enumerable) ? dim.to_a : [dim] }
      return 0 if values.any?(&:empty?)
      values.map(&:size).inject(1, :*)
    else
      size = 0
      cartesian do |v|
        next if @conditions.any? { |cond| !cond.call(v) }
        size += 1
      end
      size
    end
  end

  # Convert first `limit` combinations of parameter space to array, with respect to conditions
  def to_a(limit: nil)
    result = []
    cartesian do |v|
      result << v
      break if limit && result.size >= limit
    end
    result
  end

end

