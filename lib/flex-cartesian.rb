require 'ostruct'
require 'progressbar'
require 'colorize'
require 'json'
require 'yaml'
require 'method_source'
require 'set'
require 'logger'

require_relative 'plan'
require_relative 'flex-cartesian/flex-cartesian-core'
require_relative 'flex-cartesian/flex-cartesian-io'
require_relative 'flex-cartesian/flex-cartesian-utilities'
require_relative 'flex-cartesian/flex-cartesian-plan'
require_relative 'flex-cartesian/flex-cartesian-deprecations'



class FlexCartesian

  include FlexCartesianCore
  include FlexCartesianIO
  include FlexCartesianUtilities
  include FlexCartesianPlan
  include FlexCartesianDeprecations

end

