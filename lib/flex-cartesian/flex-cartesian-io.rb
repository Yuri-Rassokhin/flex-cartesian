module FlexCartesianIO

def width(string)
  @dimension_widths[string.to_sym] == nil ? @default_width : @dimension_widths[string.to_sym]
end

def output(separator: " | ", colorize: false, align: true, format: :plain, limit: nil, file: nil)

  out = file ? File.open(file, "w") : STDOUT

  # define column separator
  sep = if format == :csv
          [";", ","].include?(separator) ? separator : ";"
        else
          separator
        end

  # compose headers as dimension names + names of visible functions
  visible_func_names = @derived.keys - (@function_hidden || Set.new).to_a
  headers = @names.map(&:to_s) + visible_func_names.map(&:to_s)

  # print header
  case format
  when :markdown
    out.print "| "
    cells = headers.map do |h|
      cell = h.ljust(width(h))
      fmt_cell(cell, colorize: colorize, header: true)
    end
    out.puts cells.join(" | ") + " |"
    out.puts "|-" + headers.map { |h| "-" * width(h) }.join("-|-") + "-|"
  when :csv
    out.puts headers.join(sep)
  else
    out.puts headers.map { |h| fmt_cell(h, colorize: colorize, header: true, width: width(h)) }.join(sep)
  end

  # print rows
  cartesian do |vector|
    values = vector.members.map { |m| vector.send(m) } + visible_func_names.map { |f| @function_results&.dig(vector, f) }
    line = headers.zip(values).map { |(dim, val)| fmt_cell(val, colorize: colorize, width: width(dim)) }.join(sep)
    line = "| " + line + " |" if format == :markdown
    out.puts line
  end

  out.close if out.is_a?(File)
end

def import(path, format: :json)
  data = case format
  when :json
    JSON.parse(File.read(path), symbolize_names: true)
  when :yaml
    YAML.safe_load(File.read(path), symbolize_names: true)
  else
    raise ArgumentError, "Unsupported format: #{format}. Only :json and :yaml are supported."
  end

  raise TypeError, "Expected parsed data to be a Hash" unless data.is_a?(Hash)

  @dimensions = data
  self
end

def export(path, format: :json)
  case format
  when :json
    File.write(path, JSON.pretty_generate(@dimensions))
  when :yaml
    File.write(path, YAML.dump(@dimensions))
  else
    raise ArgumentError, "Unsupported format: #{format}. Only :json and :yaml are supported."
  end
end


  def from_json(path)
    data = JSON.parse(File.read(path), symbolize_names: true)
    @dimensions = data
  end

  def from_yaml(path)
    data = YAML.safe_load(File.read(path), symbolize_names: true)
    @dimensions = data
  end

  def fmt_cell(value, colorize: false, header: false, width: nil)
    str = case value
          when String then value
          else value.inspect
          end
    str = str.ljust(width) if width

    if not colorize
      str
    elsif header
      str.colorize(:yellow)
    else
      str.colorize(:cyan)
    end
  end

def table(rows, separator: " | ", colorize: false, align: true, format: :plain, file: nil)
  return if rows.nil? || rows.empty?

  sep = if format == :csv
          [";", ","].include?(separator) ? separator : ";"
        else
          separator
        end

  headers = rows.first.keys.map(&:to_s)

  widths = if align
    headers.to_h do |h|
      values = rows.map { |row| fmt_cell(row[h.to_sym], colorize: colorize, header: true).size }
      [h, [h.size, *values].max]
    end
  else
    {}
  end

  lines = []

  case format
  when :markdown
    lines << "| " + headers.map { |h| h.ljust(widths[h] || h.size) }.join(" | ") + " |"
    lines << "|-" + headers.map { |h| "-" * (widths[h] || h.size) }.join("-|-") + "-|"
  when :csv
    lines << headers.join(sep)
  else
    lines << headers.map { |h| fmt_cell(h, colorize: colorize, header: true, width: widths[h]) }.join(sep)
  end

  rows.each do |row|
    line = headers.map do |h|
      fmt_cell(row[h.to_sym], colorize: colorize, width: widths[h])
    end
    lines << line.join(sep)
  end

  if file
    File.write(file, lines.join("\n") + "\n")
  else
    lines.each { |line| puts line }
  end
end

end

module FlexOutput
  def output(separator: " | ", colorize: false, align: true)
    return puts "(empty struct)" unless respond_to?(:members) && respond_to?(:values)

    values_list = members.zip(values.map { |v| v.inspect })

    widths = align ? values_list.map { |k, v| [k.to_s.size, v.size].max } : []

    line = values_list.each_with_index.map do |(_, val), i|
      str = val.to_s
      str = str.ljust(widths[i]) if align
      colorize ? str.colorize(:cyan) : str
    end

    puts line.join(separator)
  end
end

