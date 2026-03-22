module FlexCartesianUtilities

  def dimensions(data = @dimensions, raw: false, separator: ', ', dimensions: true, values: true)
    return data.inspect if raw # by default, with no data speciaifed, we assume dimensions of Cartesian
    return nil if not dimensions and not values

    if data.is_a?(Struct) or data.is_a?(Hash) # vector in Cartesian or entire Cartesian
      data.each_pair.map { |k, v| (dimensions ? "#{k}" : "") + ((dimensions and values) ? "=" : "") + (values ? "#{v}" : "") }.join(separator)
    else
      puts "Incorrect type of dimensions: #{data.class}"
      exit
    end
  end

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

  def to_a(limit: nil)
    result = []
    cartesian do |v|
      result << v
      break if limit && result.size >= limit
    end
    result
  end

end

