module FlexCartesianDeprecations

  WARNINGS = [
      "`.dimensions` is deprecated and will be renamed to `.elements` in the next version",
      "flag `.dimensions(... raw: ...) is deprecated and will be removed in the next version, please use `.inspect` instead"
    ]

  def deprecations
    WARNINGS.each { |msg| log.warn msg }
  end

end

