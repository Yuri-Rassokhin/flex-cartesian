require 'flex-cartesian'

# Create dimension file for future use
dimension_file = './ping.json'
unless File.exist?(dimension_file)
  File.write(dimension_file, JSON.pretty_generate({
    count: [2, 4],
    size: [32, 64],
    target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]
  }))
end

# Create parameter space from the dimensions specified in the file
s = FlexCartesian.new(path: dimension_file)

# Define target functions in the parameter space
result = {} # raw result of each ping
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :ping_time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :time, order: :first) { |v| Time.now }

# Evaluate all target functions
s.func(:run, progress: true, title: "Pinging") # Sweep analysis! Benchmark all possible combinations of parameters

# Generate result
s.output(format: :csv, file: './result.csv') # save benchmark result as CSV
s.output(colorize: true, format: :markdown) # for convenience, show result in terminal

