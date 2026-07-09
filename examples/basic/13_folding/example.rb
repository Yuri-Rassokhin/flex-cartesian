require 'flex-cartesian'

s = FlexCartesian.new({count: [2, 1], size: [32, 64], target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"], iteration: 1..4 })

result = {}
s.func(:add, :command, hide: true) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f.round(2) } # fetch min time from result
s.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f.round(2) } # fetch ping loss from result

s.func(:run, title: "Pinging #{s.size} times")

puts "Initial space contains 4 iterations for each ping probe, making it #{s.size} vectors:"
s.output(format: :markdown)

# Fold 'iteration' dimension to average values; this would remove random noise from the ping probes
report = s.fold(:iteration, func: [ :time, :min ], mode: :cascade ) { |v| (v.map(&:to_f).sum / v.size).round(2) }

puts "Now we have folded `iteration` of `time` and `min` functions using average value, making it #{report.size} vectors:"
report.output(format: :markdown)

