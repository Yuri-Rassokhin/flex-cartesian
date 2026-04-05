require 'set'

module FlexCartesianUtilities

  # TODO: .index is O(N), better optimize it using intermediate Hash
  # vector commands
  def vector(command:, vector: v, dimension: nil)
    case command
    when :index
      unless dimension
        @names.map { |dim| vector(command, v, dim) }
      else
        levels = @dimensions[opts[:dimension]]
        raise "Incorrect dimension name" unless levels
        levels.index(v.dimension)
      end
    when :shift
#      TODO
    else
      raise "Incorrect vector command #{command}"
    end
  end

# shifts vector along given dimension by `stride` elements
# negative stride moves backward, positive stride moves forward
def vector_shift(v, dimension:, offset: 1)
  valid?(v)

  vector = vector_to(v, :hash)

#  TODO
  #  current_dimensional_value = vector[dimension]
# current_position = vector.keys.index[dimension]
# new_position = vector.keys[current_position + offset]

# dimensional_values = @names[dimension]
# current_position = vector_to(v, :hash).keys.index[]
# new_dimensional_value = @names[dimension
end

# obtain value of the given function on a given vector from parameter space
# modes:
# :enforce - recompute function value
# :reuse - fetch previously computed value or drop error if there isn't one
# :increment - recompute if there's no precomputed value or reuse if there's one
def value(v, function:, mode: :increment)
  v_struct = vector_to(v, :struct)
  v_hash = vector_to(v, :hash)

  res = @results[v_struct][function]

  case mode
  when :reuse
    raise "Value of #{function} function is missing on #{v_hash.inspect} vector" if res.nil?
    return res
  when :enforce
    new_res = @derived[function].call(v_struct)
    @results[v_struct][function] = new_res
    return new_res
  when :increment
    new_res = res.nil? ? @derived[function].call(v_struct) : res
    @results[v_struct][function] = new_res
    return new_res
  else
    raise "Incorrect function recompute mode: #{mode}"
  end
  res
end

# NOTE: BAD CONFLICT OF NAME "DIMENSIONS"
#def dimensions(data = @dimensions, raw: false, separator: ', ', dimensions: true, values: true, lazy: false)
#  return nil if !dimensions && !values

#  unless data.is_a?(Struct) || data.is_a?(Hash)
#    raise ArgumentError, "Incorrect type of dimensions: #{data.class}"
#  end

#  if data.is_a?(Struct)
#    return nil unless valid?(data)

#    return data.each_pair.map { |k, val|
#      (dimensions ? "#{k}" : "") +
#      ((dimensions && values) ? "=" : "") +
#      (values ? "#{val}" : "")
#    }.join(separator)
#  end

#  enum = Enumerator.new do |y|
#    cartesian(data, lazy: lazy) do |v|
#      next unless valid?(v)
#      y << dimensions(v, raw: raw, separator: separator, dimensions: dimensions, values: values, lazy: lazy)
#    end
#  end

#  return enum if lazy
#  enum.to_a.join("\n")
#end

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

  # Convert first `limit` combinations of parameter space to array
  # or convert vector in parameter space to array
  # with respect to conditions
  def to_a(data = nil, limit: nil)

    # if no `data` given we assume the data is parameter space
    if data.nil?
      result = []
      cartesian do |v|
        result << v.to_a
        break if limit && result.size >= limit
      end
      return result
    end

    # otherwise, it's a single vector
    valid?(data)
    data.values
  end

end

