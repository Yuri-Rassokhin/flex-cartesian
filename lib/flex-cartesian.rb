require 'ostruct'
require 'progressbar'
require 'colorize'
require 'json'
require 'yaml'
require 'method_source'
require 'set'

require_relative 'plan'
require_relative 'flex-cartesian/flex-cartesian-core'
require_relative 'flex-cartesian/flex-cartesian-io'
require_relative 'flex-cartesian/flex-cartesian-utilities'
require_relative 'flex-cartesian/flex-cartesian-plan'



class FlexCartesian

  include FlexCartesianCore
  include FlexCartesianIO
  include FlexCartesianUtilities
  include FlexCartesianPlan

end

