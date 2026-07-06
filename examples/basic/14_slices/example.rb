require 'flex-cartesian'

# In this example, we use `.where` to take a slice of space
# The space below has 4 dimension, thereof
# - `iteration` will be folded as an average, and so it'll disappear
# - `count` and `size` are perfect for 2D-visualization
# However, we still have 3rd dimension left: `target`, which isn't good for visualization
# To get rid of `target`, we'll take `.where` with the `target` fixed at a certain value

s = FlexCartesian.new({count: [2, 1], size: [32, 64], target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"], iteration: 1..4 })

result = {}
s.func(:add, :command, hide: true) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f.round(2) } # fetch min time from result
s.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f.round(2) } # fetch ping loss from result

s.func(:run, title: "Pinging #{s.size} times")

report = s
          .where( target: "8.8.8.8")
          .fold(:iteration, func: :time) { |v| (v.map(&:to_f).sum / v.size).round(2) }
          .output(format: :markdown)

