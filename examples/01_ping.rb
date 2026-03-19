require 'flex-cartesian'

# 1. Create dimension file for future use
dimension_file = './ping.json'
unless File.exist?(dimension_file)
  File.write(dimension_file, JSON.pretty_generate({
    count: [2, 4],
    size: [32, 64],
    target: ["8.8.8.8", "1.1.1.1", "208.67.222.222"]
  }))
end

# 2. Create Cartesian space from the dimensions specified in the file
s = FlexCartesian.new(path: dimension_file)

# 3. Optionally, define sensivity analysis technique (Morris' analysis, in this example) to assess the influence of each parameter (dimension) on the target function(s)
s.plan(:morris, trajectories: 10, step: 1, seed: 42)

# 4. Define target functions on the Cartesian space
result = {} # raw result of each ping
s.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.target}" } # ping command
s.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # capturing ping result
s.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f.round(2) } # fetch ping time from result
s.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f.round(2) } # fetch min time from result
s.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f.round(2) } # fetch ping loss from result

# 5. Run evaluations of the target functions
s.func(:run, progress: true, title: "Pinging") # Sweep analysis! Benchmark all possible combinations of parameters

# 6. Output the result
s.output(format: :csv, file: './result.csv') # save benchmark result as CSV
puts "\nEvaluated functions in the Cartesian space: time, min, and loss\n"
s.output(colorize: true) # for convenience, show result in terminal

# 7. Once we define sensitivity analysis technique, output its result as well
puts "\nSensitivity of the function 'time'\n"
s.sensitivity(function: :time, colorize: true, recommend: true) # Assess influence of the dimensional parameters on "time" target functions and recommend next actions
puts "\nSensitivity of the function 'min'\n"
s.sensitivity(function: :min, colorize: true, recommend: true) # Assess influence of the dimensional parameters on "min" target functions and recommend next actions

