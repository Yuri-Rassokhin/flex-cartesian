require "csv"
require "json"

def generate_surface_html(csv_file, x_column, y_column, z_column, output_file: "surface.html")
  table = CSV.read(csv_file, headers: true, col_sep: ";")

  headers = table.headers.map { |h| h&.strip }

  unless headers.include?(x_column)
    raise ArgumentError, "Column '#{x_column}' not found in CSV. Available columns: #{headers.inspect}"
  end

  unless headers.include?(y_column)
    raise ArgumentError, "Column '#{y_column}' not found in CSV. Available columns: #{headers.inspect}"
  end

  unless headers.include?(z_column)
    raise ArgumentError, "Column '#{z_column}' not found in CSV. Available columns: #{headers.inspect}"
  end

  normalized_rows = table.map do |row|
    h = {}
    table.headers.each do |original_header|
      normalized_header = original_header&.strip
      h[normalized_header] = row[original_header]&.strip
    end
    h
  end

  x_values = normalized_rows.map { |r| numeric_or_string(r[x_column]) }.compact.uniq.sort_by { |v| sortable_key(v) }
  y_values = normalized_rows.map { |r| numeric_or_string(r[y_column]) }.compact.uniq.sort_by { |v| sortable_key(v) }

  x_index = x_values.each_with_index.to_h
  y_index = y_values.each_with_index.to_h

  z_matrix = Array.new(y_values.size) { Array.new(x_values.size, nil) }

  normalized_rows.each do |row|
    x = numeric_or_string(row[x_column])
    y = numeric_or_string(row[y_column])
    z = numeric_or_string(row[z_column])

    next if x.nil? || y.nil? || z.nil?

    yi = y_index[y]
    xi = x_index[x]
    z_matrix[yi][xi] = z
  end

  html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Surface Plot</title>
      <script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script>
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          font-family: Arial, sans-serif;
        }
        #chart {
          width: 100vw;
          height: 100vh;
        }
      </style>
    </head>
    <body>
      <div id="chart"></div>
      <script>
        const data = [{
          type: "surface",
          x: #{JSON.generate(x_values)},
          y: #{JSON.generate(y_values)},
          z: #{JSON.generate(z_matrix)},
          connectgaps: false
        }];

        const layout = {
          title: #{JSON.generate("#{z_column} as a function of #{x_column} and #{y_column}")},
          scene: {
            xaxis: { title: #{JSON.generate(x_column)} },
            yaxis: { title: #{JSON.generate(y_column)} },
            zaxis: { title: #{JSON.generate(z_column)} }
          },
          margin: { l: 0, r: 0, b: 0, t: 50 }
        };

        Plotly.newPlot("chart", data, layout, { responsive: true });
      </script>
    </body>
    </html>
  HTML

  File.write(output_file, html)
  output_file
end

def numeric_or_string(value)
  return nil if value.nil?

  s = value.to_s.strip
  return nil if s.empty?

  Integer(s)
rescue ArgumentError
  begin
    Float(s)
  rescue ArgumentError
    s
  end
end

def sortable_key(value)
  value.is_a?(Numeric) ? [0, value] : [1, value.to_s]
end

generate_surface_html(
  "yolo-arm-a1.csv",
  "iterate_processes",
  "iterate_requests",
  "inference",
  output_file: "yolo-arm-a1.html"
)
