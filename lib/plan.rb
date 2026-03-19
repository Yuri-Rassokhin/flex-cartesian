require_relative 'output'

# This wrapper class describes 'benchmark plan'
# Effectively, Plan objects picks selected points from
# Cartesian space instead of sweeping over the entire space
class Plan

  # MUST return same kind of Struct as cartesian iterator
  def each_point(&blk)
    raise NotImplementedError, "#{self.class} must implement #each_point"
  end

  def size
    nil
  end

  def analysis_type
    :none
  end

  def metadata
    {}
  end

  def analyze(results:, metric:)
    raise NotImplementedError, "#{self.class} does not implement #analyze"
  end

  def recommend(rows, metric:)
    rows
  end

end

