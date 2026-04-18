require 'flex-cartesian'

s = FlexCartesian.new({count: [2, 4], size: [32, 64], target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]})

result = {}
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f.round(2) } # fetch min time from result
s.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f.round(2) } # fetch ping loss from result

s.func(:run, progress: true, title: "Pinging")

s.output(colorize: true)
