module FlexCartesianVisualization
  require "csv"
  require "json"
  require "tempfile"

  def visualize(format: :html, x:, y:, func:, output: nil, text: :dark, show_legend: false, show_z_title: true, show_grid: true, equal_axes: true, start_at_zero: true, show_plot_title: false, bg_color: 'transparent', font_color: nil, grid_color: nil, colorscale: 'Bluered')
    raise "X-axis of visualization cannot be empty" unless x
    
    funcs = Array(func).map(&:to_s)
    raise "Functions of visualization cannot be empty" if funcs.empty?

    # if colors aren't specified, we'll pick them based on theme
    actual_font_color = font_color || (text == :dark ? '#333333' : '#edf5ff')
    actual_grid_color = grid_color || (text == :dark ? 'rgba(0,0,0,0.15)' : 'rgba(255,255,255,0.15)')

    case format
    when :html
      generate_html(
        x: x.to_s,
        y: y.to_s,
        func: funcs,
        output: output,
        show_legend: show_legend,
        show_z_title: show_z_title,
        show_grid: show_grid,
        equal_axes: equal_axes,
        start_at_zero: start_at_zero,
        show_plot_title: show_plot_title,
        bg_color: bg_color,
        font_color: actual_font_color,
        grid_color: actual_grid_color,
        colorscale: colorscale
      )
    else
      raise "Incorrect visualize format #{format}"
    end
  end

  def generate_html(x:, y: nil, func:, output:, show_legend:, show_z_title:, show_grid:, equal_axes:, start_at_zero:, show_plot_title:, bg_color:, font_color:, grid_color:, colorscale:)
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

    func.each do |f|
      unless headers.include?(f)
        raise ArgumentError, "Column '#{f}' not found in CSV. Available columns: #{headers.inspect}"
      end
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

    z_matrices = {}
    func.each do |f|
      z_matrices[f] = Array.new(y_values.size) { Array.new(x_values.size, nil) }
    end

    normalized_rows.each do |row|
      val_x = numeric_or_string(row[x])
      val_y = numeric_or_string(row[y])

      next if val_x.nil? || val_y.nil?

      yi = y_index[val_y]
      xi = x_index[val_x]

      func.each do |f|
        val_z = numeric_or_string(row[f])
        z_matrices[f][yi][xi] = val_z unless val_z.nil?
      end
    end

    plotly_data = func.map.with_index do |f, index|
      {
        type: "surface",
        name: f,
        x: x_values,
        y: y_values,
        z: z_matrices[f],
        opacity: 0.85,
        hovertemplate: "#{x}: %{x}<br>#{y}: %{y}<br>#{f}: %{z}<extra></extra>",
        connectgaps: false,
        showscale: index == 0 ? show_legend : false,
        colorscale: colorscale,
        contours: {
          x: { show: show_grid, color: '#ffffff', width: 1 }, # 'color' is hardcoded to white - TODO: make it tunable
          y: { show: show_grid, color: '#ffffff', width: 1 }
        }
      }
    end

    combined_func_names = func.join(", ")
    zaxis_title_js = show_z_title ? "title: #{JSON.generate(combined_func_names)}," : "title: '',"
    grid_flag = show_grid ? 'true' : 'false'
    aspect_mode_js = equal_axes ? "aspectmode: 'cube'," : "aspectmode: 'auto',"
    range_mode_js = start_at_zero ? "rangemode: 'tozero'," : ""
    plot_title = show_plot_title ? "title: #{JSON.generate("#{combined_func_names} (#{x}, #{y})")}," : "title: '',"

    plotly_bg = bg_color == 'transparent' ? 'rgba(0,0,0,0)' : bg_color

    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Surface Plot</title>
        <script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script>
        <style>
          html, body {
            background-color: #{bg_color} !important;
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
          const data = #{JSON.generate(plotly_data)};

          const layout = {
            #{plot_title}
            paper_bgcolor: '#{plotly_bg}',
            plot_bgcolor: '#{plotly_bg}',
            font: { color: '#{font_color}' }, // Применяется ко всему тексту (заголовок, названия осей, значения)
            scene: {
            #{aspect_mode_js}
              xaxis: {
                title: #{JSON.generate(x)},
                showgrid: #{grid_flag},
                zeroline: #{grid_flag},
                gridcolor: '#{grid_color}', // Цвет линий сетки
                zerolinecolor: '#{grid_color}', // Цвет нулевой линии
                linecolor: '#{grid_color}', // Цвет линии самой оси
                #{range_mode_js}
              },
              yaxis: {
                title: #{JSON.generate(y)},
                showgrid: #{grid_flag},
                zeroline: #{grid_flag},
                gridcolor: '#{grid_color}',
                zerolinecolor: '#{grid_color}',
                linecolor: '#{grid_color}',
                #{range_mode_js}
              },
              zaxis: {
                #{zaxis_title_js}
                showgrid: #{grid_flag},
                zeroline: #{grid_flag},
                gridcolor: '#{grid_color}',
                zerolinecolor: '#{grid_color}',
                linecolor: '#{grid_color}',
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

    output ? File.write(output, html) : STDOUT.write(html)
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
