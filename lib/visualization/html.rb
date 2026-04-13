module FlexCartesianVisualization

require "csv"
require "json"
require 'tempfile'

def visualize(format: :html, x:, y:, function:, output: nil, show_legend: true, show_z_title: true, show_grid: true, equal_axes: false, start_at_zero: true, show_plot_title: true)
  raise "X-asis of visialization cannot be empty" unless x
  raise "Function of visialization cannot be empty" unless function

  case format
  when :html
    generate_html(x: x.to_s, y: y.to_s, function: function.to_s, output: output, show_legend: show_legend, show_z_title: show_z_title, show_grid: show_grid, equal_axes: equal_axes, start_at_zero: start_at_zero, show_plot_title: show_plot_title)
  else
    raise "Incorrect visualize format #{format}"
  end
end

def generate_html(x:, y: nil, function:, output:, show_legend:, show_z_title:, show_grid:, equal_axes:, start_at_zero:, show_plot_title:)
  # TODO: eliminate the need for temp file
  temp_file = Tempfile.new
  output(format: :csv, file: temp_file)
  table = CSV.read(temp_file, headers: true, col_sep: ";")
  temp_file.unlink

  headers = table.headers.map { |h| h&.strip }

  unless headers.include?(x)
    raise ArgumentError, "Column '#{x}' not found in CSV. Available columns: #{headers.inspect}"
  end

  unless headers.include?(y)
    raise ArgumentError, "Column '#{y}' not found in CSV. Available columns: #{headers.inspect}"
  end

  unless headers.include?(function)
    raise ArgumentError, "Column '#{function}' not found in CSV. Available columns: #{headers.inspect}"
  end

  normalized_rows = table.map do |row|
    h = {}
    table.headers.each do |original_header|
      normalized_header = original_header&.strip
      h[normalized_header] = row[original_header]&.strip
    end
    h
  end

  x_values = normalized_rows.map { |r| numeric_or_string(r[x]) }.compact.uniq.sort_by { |v| sortable_key(v) }
  y_values = normalized_rows.map { |r| numeric_or_string(r[y]) }.compact.uniq.sort_by { |v| sortable_key(v) }

  x_index = x_values.each_with_index.to_h
  y_index = y_values.each_with_index.to_h

  z_matrix = Array.new(y_values.size) { Array.new(x_values.size, nil) }

normalized_rows.each do |row|
    val_x = numeric_or_string(row[x])
    val_y = numeric_or_string(row[y])
    val_z = numeric_or_string(row[function])

    next if val_x.nil? || val_y.nil? || val_z.nil?

    yi = y_index[val_y]
    xi = x_index[val_x]
    z_matrix[yi][xi] = val_z
  end

  zaxis_title_js = show_z_title ? "title: #{JSON.generate(function)}," : "title: '',"
  grid_flag = show_grid ? 'true' : 'false'

  aspect_mode_js = equal_axes ? "aspectmode: 'cube'," : "aspectmode: 'auto',"

  range_mode_js = start_at_zero ? "rangemode: 'tozero'," : ""

  plot_title = show_plot_title ? "title: #{JSON.generate("#{function} (#{x}, #{y})")}," : "title: '',"


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
          hovertemplate: "#{x}: %{x}<br>#{y}: %{y}<br>#{function}: %{z}<extra></extra>",
          connectgaps: false,
          showscale: #{show_legend ? 'true' : 'false'},
          // Задаем светло-голубую цветовую шкалу (от бледного к более насыщенному)
          colorscale: 'Bluered',
          // Добавляем сетку на саму поверхность
          contours: {
            x: {
              show: #{grid_flag},
              color: '#ffffff', // Белый цвет линий (можно заменить на '#9e9e9e' для серых)
              width: 1          // Толщина линий
            },
            y: {
              show: #{grid_flag},
              color: '#ffffff',
              width: 1
            }
          }
        }];

        const layout = {
          #{plot_title}
          scene: {
          #{aspect_mode_js}
            xaxis: {
              title: #{JSON.generate(x)},
              showgrid: #{grid_flag},
              zeroline: #{grid_flag},
              #{range_mode_js}
            },
            yaxis: {
              title: #{JSON.generate(y)},
              showgrid: #{grid_flag},
              zeroline: #{grid_flag},
              #{range_mode_js}
            },
            zaxis: {
              #{zaxis_title_js}
              showgrid: #{grid_flag},
              zeroline: #{grid_flag},
              #{range_mode_js}
            }
          },
          margin: { l: 0, r: 0, b: 0, t: 50 }
        };

        Plotly.newPlot("chart", data, layout, { responsive: true });
      </script>
    </body>
    </html>
  HTML

  File.write(output ? output : STDOUT, html)
  output
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

end

