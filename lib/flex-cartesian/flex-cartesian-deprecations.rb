module FlexCartesianDeprecations

  WARNINGS = [
      "`.dimensions` is deprecated and will be renamed to `.elements` in the next version",
      "flag `.dimensions(... raw: ...) is deprecated and will be removed in the next version, please use `.inspect` instead"
    ]

  def deprecations
    return if ENV['FLEXCARTESIAN_DEPRECATION_SILENT'] == '1'
    WARNINGS.each { |msg| log.warn msg }
  end

end

