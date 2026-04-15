require 'flex-cartesian'

s = FlexCartesian.new({
  count: [1],
  interval: [0.2],
  size: [64, 512, 1400, 1500, 4096, 8192],  
  target: [ # we're pinging AWS DynamoDB
    "dynamodb.eu-central-1.amazonaws.com",   # Frankfurt
    "dynamodb.us-east-1.amazonaws.com",      # Virginia, US
    "dynamodb.sa-east-1.amazonaws.com",      # Sao Paolo
    "dynamodb.ap-northeast-1.amazonaws.com", # Tokio
    "dynamodb.af-south-1.amazonaws.com"      # Capetown
  ]
})

result = {}
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} -i #{v.interval} #{v.target}" }
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` }
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) }
s.func(:run, progress: true)

# visualize behavioural blueprint as a 2D-heatmap
space.visualize(x: :size, y: :target, function: :time)

# quantify influence of the parameters in the blueprint
space.analyzer(:morris, trajectories: 10, step: 0.1, seed: 42).output(function: :time)

