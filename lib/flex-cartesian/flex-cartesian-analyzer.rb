require_relative '../analyzer'

module FlexCartesianAnalyzer

  def analyzer(type, **opts)
    case type
    when :morris
      require_relative '../analyzers/morris'
      Morris.new(self, **opts)
    else
      raise ArgumentError, "Unknown analyzer: #{type}"
    end
  end

end

