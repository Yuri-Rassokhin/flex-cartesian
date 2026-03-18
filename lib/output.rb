
module Output
  module_function

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
