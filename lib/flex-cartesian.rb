require 'ostruct'
require 'progressbar'
require 'colorize'
require 'json'
require 'yaml'

module FlexOutput
  def output(separator: " | ", colorize: false, align: false)
    return puts "(empty struct)" unless respond_to?(:members) && respond_to?(:values)

    values_list = members.zip(values.map { |v| v.inspect })

    # calculate widths, if align required
    widths = align ? values_list.map { |k, v| [k.to_s.size, v.size].max } : []

    line = values_list.each_with_index.map do |(_, val), i|
      str = val.to_s
      str = str.ljust(widths[i]) if align
      colorize ? str.colorize(:cyan) : str
    end

    puts line.join(separator)
  end
end

class FlexCartesian
  attr :dimensions

  def initialize(dimensions = nil)
    @dimensions = dimensions
  end

  def cartesian(dims = nil, lazy: false)
    dimensions = dims || @dimensions
    return nil unless dimensions.is_a?(Hash)

    names = dimensions.keys
    values = dimensions.values.map { |dim| dim.is_a?(Enumerable) ? dim.to_a : [dim] }

    return to_enum(:cartesian, dims, lazy: lazy) unless block_given?
    return if values.any?(&:empty?)

    struct_class = Struct.new(*names).tap { |sc| sc.include(FlexOutput) }

    base = values.first.product(*values[1..])
    enum = lazy ? base.lazy : base

    enum.each do |combo|
      yield struct_class.new(*combo)
    end
  end

  def size(dims = nil)
    dimensions = dims || @dimensions
    return 0 unless dimensions.is_a?(Hash)

    values = dimensions.values.map { |dim| dim.is_a?(Enumerable) ? dim.to_a : [dim] }
    return 0 if values.any?(&:empty?)

    values.map(&:size).inject(1, :*)
  end

  def to_a(limit: nil)
    result = []
    cartesian do |v|
      result << v
      break if limit && result.size >= limit
    end
    result
  end

  def progress_each(dims = nil, lazy: false, title: "Processing")
    total = size(dims)
    bar = ProgressBar.create(title: title, total: total, format: '%t [%B] %p%% %e')

    cartesian(dims, lazy: lazy) do |v|
      yield v
      bar.increment
    end
  end

def output(separator: " | ", colorize: false, align: false, format: :plain, limit: nil)
  rows = []
  cartesian do |v|
    rows << v
    break if limit && rows.size >= limit
  end
  return if rows.empty?

  headers = rows.first.members.map(&:to_s)

  # Get widths
  widths = align ? headers.to_h { |h|
    [h, [h.size, *rows.map { |r| fmt_cell(r[h], false).size }].max]
  } : {}

  # Title
  case format
  when :markdown
    puts "| " + headers.map { |h| h.ljust(widths[h] || h.size) }.join(" | ") + " |"
    puts "|-" + headers.map { |h| "-" * (widths[h] || h.size) }.join("-|-") + "-|"
  when :csv
    puts headers.join(",")
  else
    puts headers.map { |h| fmt_cell(h, colorize, widths[h]) }.join(separator)
  end

  # Rows
  rows.each do |row|
    line = headers.map { |h| fmt_cell(row[h], colorize, widths[h]) }
    puts format == :csv ? line.join(",") : line.join(separator)
  end
end

  def self.from_json(path)
    data = JSON.parse(File.read(path), symbolize_names: true)
    new(data)
  end

  def self.from_yaml(path)
    data = YAML.safe_load(File.read(path), symbolize_names: true)
    new(data)
  end

private

def fmt_cell(value, colorize, width = nil)
  str = case value
        when String then value  # rows - without inspect
        else value.inspect      # the rest is good to inspect
        end
  str = str.ljust(width) if width
  colorize ? str.colorize(:cyan) : str
end

end

