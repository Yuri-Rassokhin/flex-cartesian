module FlexCartesianVisualization
  require "csv"
  require "json"
  require "tempfile"

  # Теперь метод принимает массив `functions:`
  def visualize(format: :html, x:, y:, functions:, output: nil, show_legend: false, show_z_title: true, show_grid: true, equal_axes: true, start_at_zero: true, show_plot_title: false, bg_color: 'transparent', font_color: '#edf5ff', grid_color: 'rgba(255,255,255,0.15)', colorscale: 'Bluered')
    raise "X-axis of visualization cannot be empty" unless x
    
    # Приводим к массиву на случай, если передали одно значение
    funcs = Array(functions).map(&:to_s)
    raise "Functions of visualization cannot be empty" if funcs.empty?

    case format
    when :html
      generate_html(
        x: x.to_s,
        y: y.to_s,
        functions: funcs,
        output: output,
        show_legend: show_legend,
        show_z_title: show_z_title,
        show_grid: show_grid,
        equal_axes: equal_axes,
        start_at_zero: start_at_zero,
        show_plot_title: show_plot_title,
        bg_color: bg_color,
        font_color: font_color,
        grid_color: grid_color,
        colorscale: colorscale
      )
    else
      raise "Incorrect visualize format #{format}"
    end
  end

  def generate_html(x:, y: nil, functions:, output:, show_legend:, show_z_title:, show_grid:, equal_axes:, start_at_zero:, show_plot_title:, bg_color:, font_color:, grid_color:, colorscale:)
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

    # Проверяем наличие всех запрошенных функций в CSV
    functions.each do |func|
      unless headers.include?(func)
        raise ArgumentError, "Column '#{func}' not found in CSV. Available columns: #{headers.inspect}"
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

    # Создаем хэш Z-матриц для каждой функции
    z_matrices = {}
    functions.each do |func|
      z_matrices[func] = Array.new(y_values.size) { Array.new(x_values.size, nil) }
    end

    normalized_rows.each do |row|
      val_x = numeric_or_string(row[x])
      val_y = numeric_or_string(row[y])

      next if val_x.nil? || val_y.nil?

      yi = y_index[val_y]
      xi = x_index[val_x]

      # Заполняем матрицы для всех переданных функций
      functions.each do |func|
        val_z = numeric_or_string(row[func])
        z_matrices[func][yi][xi] = val_z unless val_z.nil?
      end
    end

    # Формируем данные для Plotly через руби-хэши для безопасной конвертации в JSON
    plotly_data = functions.map.with_index do |func, index|
      {
        type: "surface",
        name: func,
        x: x_values,
        y: y_values,
        z: z_matrices[func],
        opacity: 0.85, # Добавлена прозрачность для наложения слоев
        hovertemplate: "#{x}: %{x}<br>#{y}: %{y}<br>#{func}: %{z}<extra></extra>",
        connectgaps: false,
        showscale: index == 0 ? show_legend : false, # Показываем легенду только для первого графика, чтобы не захламлять экран
        colorscale: colorscale,
        contours: {
          x: { show: show_grid, color: grid_color, width: 1 },
          y: { show: show_grid, color: grid_color, width: 1 }
        }
      }
    end

    combined_func_names = functions.join(", ")
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
          // Данные полностью сформированы в Ruby
          const data = #{JSON.generate(plotly_data)};

          const layout = {
            #{plot_title}
            paper_bgcolor: '#{plotly_bg}',
            plot_bgcolor: '#{plotly_bg}',
            font: { color: '#{font_color}' },
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

