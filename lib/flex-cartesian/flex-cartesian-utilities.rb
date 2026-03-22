module FlexCartesianUtilities

  def dimensions(data = @dimensions, raw: false, separator: ', ', dimensions: true, values: true)

    # DEPRECATED
    puts "WARNING: `.dimensions` will be renamed to `.elements` in the next version"

    # DEPRECATED FLAG `raw`, TO BE REMOVED
    if raw
      puts "WARNING: flag `raw` is deprecated in `.dimensions` and will be removed in the next version, please use `.inspect` instead"
      return data.inspect
    end

    # edge case: nothing specified
    return nil if !dimensions && !values

    # edge case: data must be either Struct (vector in parameter space) or Hash (parameter space)
    if not (data.is_a?(Struct) or data.is_a?(Hash))
        puts "Incorrect type of dimensions: #{data.class}"
        raise ArgumentError
    end

    # if `data` is a vector, process it
    if data.is_a?(Struct)
      return nil unless valid?(data)
      return data.each_pair.map { |k, val| (dimensions ? "#{k}" : "") + ((dimensions && values) ? "=" : "") + (values ? "#{val}" : "") }.join(separator)
    end

    # finally, if `data` is entire parameter space, recurseively process it vector by vector
    result = []
    cartesian(data) do |v|
      next unless valid?(v)
      result << dimensions(v, raw: raw, separator: separator, dimensions: dimensions, values: values)
    end

    result.join("\n")
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

