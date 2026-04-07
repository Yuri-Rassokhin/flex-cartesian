require 'ostruct'
require 'progressbar'
require 'colorize'
require 'json'
require 'yaml'
require 'method_source'
require 'set'
require 'logger'

require_relative 'flex-cartesian/flex-cartesian-core'
require_relative 'flex-cartesian/flex-cartesian-io'
require_relative 'flex-cartesian/flex-cartesian-utilities'
require_relative 'flex-cartesian/flex-cartesian-analyzer'
require_relative 'flex-cartesian/flex-cartesian-deprecations'
require_relative 'visualization/html'



class FlexCartesian

  include FlexCartesianCore
  include FlexCartesianIO
  include FlexCartesianUtilities
  include FlexCartesianAnalyzer
  include FlexCartesianDeprecations
  include FlexCartesianVisualization

end

