require 'flex-cartesian'

s = FlexCartesian.new({count: [2, 1], size: [32, 64], target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]})

result = {}
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f.round(2) } # fetch min time from result
s.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f.round(2) } # fetch ping loss from result

s.func(:run, title: "Pinging #{s.size} times")

s.output

# Please note that the previously computed space will be assigned to one of the newly created points in the timeline
s.dim(:add, { iteration: 1..4 } )

Stdlib.add_timing(s, iteration: true)

s.func(:run, title: "Pinging extra iterations")

s.output
