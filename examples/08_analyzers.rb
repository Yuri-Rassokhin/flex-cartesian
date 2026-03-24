require 'flex-cartesian'

# CREATE PARAMETER SPACE

s = FlexCartesian.new({
    count: [2, 4],
    size: [32, 64],
    target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]
  })

# DEFINE PLAN FOR SCREENING OF THE PARAMETER SPACE
# Plan is a screening technique that traverses parameter space, usually using smaller subset of its combinations, and investigates its properties
# In this example, plan investigates the influence of dimensional parameters (count, size, and target) on the given function: ping time.

# Define target function that will be investigted by the plan
result = {} # raw result of each ping
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # result of ping command
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from the result

# Evaluate target function `time` on the combinations from parameter space defined by the plan
s.func(:run, progress: true, title: "Pinging")

# create three analyzers of the target functions
m1 = s.analyzer(:morris, trajectories: 10, step: 1, seed: 42)
m2 = s.analyzer(:morris, trajectories: 20, step: 1, seed: 42)

puts "\nWe apply #{m1.name}. #{m1.description}.\n\n"
puts "\n#{m1.name}: trajectories = 5, step = 1, seed = 42"
m1.output(function: :time, colorize: true)
puts "\n#{m2.name}: trajectories = 20, step = 1, seed = 42"
m2.output(function: :time, colorize: true)

# Once we have `time` function evaluated, we can apply the plan to analyze its properties
# Morris' method assesses the influence of each dimensional parameter on the target function
# Additionally, it assesses the nature of such influence - linear or non-linear
# Optionally, the plan generates recommendations on the next step in the parameter space analysis - if `recommend` is enabled

