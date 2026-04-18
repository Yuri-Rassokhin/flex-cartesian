require 'flex-cartesian'

space = FlexCartesian.new({
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
space.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} -i #{v.interval} #{v.target}" }
space.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` }
space.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f }
space.func(:add, :cap) { |v| 150 }
space.func(:run, progress: true)

# visualize behavioural blueprint as a 2D-heatmap
space.visualize(x: :size, y: :target, func: [ :time, :cap ], output: "./examples/09_ping_visualize/viz.html")

puts "Visualization saved to ./examples/09_ping_visualize/viz.html"

