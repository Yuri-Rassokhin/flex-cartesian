module FlexCartesianIO

# unified wrapper method for output
def output(rows = nil, **opts)
  if rows == nil
    cartesian_output(**opts)
  else
    table_output(rows, **opts)
  end
end

  # internal method
  def separator(sep, format:)
    result = if format == :csv
            [";", ","].include?(sep) ? sep : ";"
          else
            sep
          end
  end

  # internal method for printing headers
  def output_headers(headers:, format:, widths:, stream:, colorize:, separator:)
    case format
    when :markdown
      stream.print "| "
      cells = headers.map.with_index do |h,i|
        cell = h.ljust(widths[i])
        fmt_cell(cell, colorize: colorize, header: true)
      end
      stream.puts cells.join(" | ") + " |"
      stream.puts "|-" + headers.map.with_index { |h,i| "-" * widths[i] }.join("-|-") + "-|"
    when :csv
      stream.puts headers.join(separator)
    else
      stream.puts headers.map.with_index { |h,i| fmt_cell(h, colorize: colorize, header: true, width: widths[i]) }.join(separator)
    end
  end

# internal method for output from space
def cartesian_output(separator: " | ", colorize: false, align: true, format: :plain, limit: nil, file: nil)

  # output stream
  out = file ? File.open(file, "w") : STDOUT

  # column separator
  sep = separator(separator, format: format)

  # table headers
  visible_func_names = @derived.keys - (@function_hidden || Set.new).to_a
  headers = @names.map(&:to_s) + visible_func_names.map(&:to_s)

  # column widths
  widths = headers.map { |h| @dimension_widths[h.to_sym] == nil ? @default_width : @dimension_widths[h.to_sym] }

  # print headers
  output_headers(headers: headers, format: format, widths: widths, stream: out, colorize: colorize, separator: separator)

  # print rows
  cartesian do |vector|
    values = vector.members.map { |m| vector.send(m) } + visible_func_names.map { |f| @function_results&.dig(vector, f) }
    line = headers.zip(values).map.with_index { |(dim, val), i| fmt_cell(val, colorize: colorize, width: widths[i]) }.join(sep)
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

  # internal method
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

# THIS NEEDS TO BE MERGED INTO standard output method
def table_output(rows, separator: " | ", colorize: false, align: true, format: :plain, file: nil)
  return if rows.nil? || rows.empty?

  # output stream
  out = file ? File.open(file, "w") : STDOUT

  # column separator
  sep = separator(separator, format: format)

  # table headers
  headers = rows.first.keys.map(&:to_s)

  # column widths
  widths = if align
    headers.to_h do |h|
      values = rows.map { |row| fmt_cell(row[h.to_sym], colorize: colorize, header: true).size }
      [h, [h.size, *values].max]
    end
  else
    {}
  end

  # print headers
  output_headers(headers: headers, format: format, widths: widths.values, stream: out, colorize: colorize, separator: separator)

#  case format
#  when :markdown
#    out.puts "| " + headers.map { |h| h.ljust(widths[h] || h.size) }.join(" | ") + " |"
#    out.puts "|-" + headers.map { |h| "-" * (widths[h] || h.size) }.join("-|-") + "-|"
#  when :csv
#    out.puts headers.join(sep)
#  else
#    out.puts headers.map { |h| fmt_cell(h, colorize: colorize, header: true, width: widths[h]) }.join(sep)
#  end

  rows.each do |row|
    line = headers.map { |h| fmt_cell(row[h.to_sym], colorize: colorize, width: widths[h]) }
    out.puts line.join(sep)
  end

  out.close if out.is_a?(File)
end

end

module FlexOutput
  def cartesian_output(separator: " | ", colorize: false, align: true)
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

