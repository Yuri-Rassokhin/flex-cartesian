require 'flex-cartesian'

s = FlexCartesian.new({count: [2, 4], size: [32, 64], target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]})

counter = 1
result = {}
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :time) { |v| puts "#{counter}"; counter+=1; v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f.round(2) } # fetch min time from result
s.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f.round(2) } # fetch ping loss from result

puts "Pinging #{s.size} times..."
s.func(:run, progress: false, title: "Pinging")

s.output

puts "Adding temporal iterations..."
# Please note that the previously computed space will be assigned to one of the newly created points in the timeline
s.dim(:add, { timeline: [*1..4] } )

# For convenience, we'll add a unique timestamp to each point at the timeline
s.func(:add, :blueprint_timestamp, order: :first) { |v| time ||= Time.now.strftime("%H:%M:%S - %d-%m-%Y"); time }

counter = 1
s.func(:run)
