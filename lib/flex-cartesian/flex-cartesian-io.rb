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
    case format
    when :csv
      [";", ","].include?(sep) ? sep : ";"
    when :markdown
      "|"
    else
      sep
    end
  end

  # internal method for printing headers
  def output_headers(headers:, format:, widths:, stream:, colorize:, separator:, file:)
    case format
    when :markdown
      stream.print separator
      cells = headers.map.with_index do |h,i|
        cell = h.ljust(widths[i])
        fmt_cell(cell, file: file, colorize: colorize, header: true)
      end
      stream.puts cells.join(separator) + separator
      stream.puts separator + headers.map.with_index { |h,i| "-" * widths[i] }.join(separator) + separator
    when :csv
      stream.puts headers.map.with_index { |h,i| fmt_cell(h, file: file, colorize: colorize, header: true, width: widths[i]) }.join(separator)
    else
      stream.puts separator + headers.map.with_index { |h,i| fmt_cell(h, file: file, colorize: colorize, header: true, width: widths[i]) }.join(separator) + separator
    end
  end

# internal method for output from space
def cartesian_output(separator: "|", colorize: true, format: :plain, limit: nil, file: nil)

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
  output_headers(file: file, headers: headers, format: format, widths: widths, stream: out, colorize: colorize, separator: sep)

  # print rows
  cartesian do |vector|
    values = vector.members.map { |m| vector.send(m) } + visible_func_names.map { |f| @function_results&.dig(vector, f) }
    line = headers.zip(values).map.with_index { |(dim, val), i| fmt_cell(val, file: file, colorize: colorize, width: widths[i]) }.join(sep)
    case format
    when :plain
      out.puts sep + line + sep
    when :markdown
      out.puts sep + line + sep
    when :csv
      out.puts line
    end
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
  def fmt_cell(value, file:, colorize: false, header: false, width: nil)
    str = case value
          when String then value
          else value.inspect
          end
    str = str.ljust(width) if width

    # output to file must NOT be colorized to avoid special characters in file
    return str if file

    if not colorize
      str
    elsif header
      str.colorize(:yellow)
    else
      str.colorize(:cyan)
    end
  end

# THIS NEEDS TO BE MERGED INTO standard output method
def table_output(rows, separator: "|", colorize: true, format: :plain, file: nil)
  return if rows.nil? || rows.empty?

  # output stream
  out = file ? File.open(file, "w") : STDOUT

  # column separator
  sep = separator(separator, format: format)

  # table headers
  headers = rows.first.keys.map(&:to_s)

  # column widths
  widths = headers.to_h do |h|
            values = rows.map { |row| row[h.to_sym].to_s.size }
            [h, [h.size, *values].max]
          end

  # print headers
  output_headers(file: file, headers: headers, format: format, widths: widths.values, stream: out, colorize: colorize, separator: sep)

  rows.each do |row|
    line = headers.map { |h| fmt_cell(row[h.to_sym], file: file, colorize: colorize, width: widths[h]) }.join(sep)
    case format
    when :plain
      out.puts sep + line + sep
    when :markdown
      out.puts sep + line + sep
    when :csv
      out.puts line + sep
    end
  end

  out.close if out.is_a?(File)
end

end

module FlexOutput
  def cartesian_output(separator: "|", colorize: true)
    return puts "(empty struct)" unless respond_to?(:members) && respond_to?(:values)

    values_list = members.zip(values.map { |v| v.inspect })

    widths = values_list.map { |k, v| [k.to_s.size, v.size].max }

    line = values_list.each_with_index.map do |(_, val), i|
      str = val.to_s
      str = str.ljust(widths[i])
      colorize ? str.colorize(:cyan) : str
    end

    puts line.join(separator)
  end
end

