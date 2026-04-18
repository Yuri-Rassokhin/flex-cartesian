require 'flex-cartesian'

s = FlexCartesian.new({count: [2, 4], size: [32, 64], target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]})

result = {}
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" }
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` }
s.func(:add, :ping_time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) }
s.func(:add, :timestamp, order: :first) { |v| Time.now("%H:%M:%S - %d-%m-%Y") }

s.func(:run, progress: true, title: "Pinging")

s.output(colorize: true, format: :markdown)
