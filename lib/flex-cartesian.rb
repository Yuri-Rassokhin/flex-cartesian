require 'ostruct'
require 'progressbar'
require 'colorize'
require 'json'
require 'yaml'
require 'method_source'

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

class FlexCartesian
  attr :dimensions

  def initialize(dimensions = nil)
    @dimensions = dimensions
    @conditions = []
    @derived = {}
  end

  def cond(command = :print, index: nil, &block)
    case command
    when :set
      raise ArgumentError, "Block required" unless block_given?
      @conditions << block
      self
    when :unset
      raise ArgumentError, "Index of the condition required" unless index
      @conditions.delete_at(index)
    when :clear 
      @conditions.clear
      self
    when :print 
      return if @conditions.empty?
      @conditions.each_with_index { |cond, idx| puts "#{idx} | #{cond.source.gsub(/^.*?\s/, '')}" }
    else
      raise ArgumentError, "unknown condition command: #{command}"
    end
  end

  def add_function(name, &block)
    raise ArgumentError, "Block required" unless block_given?
    @derived[name.to_sym] = block
  end

  def remove_function(name)
    @derived.delete(name.to_sym)
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
    struct_instance = struct_class.new(*combo)

    @derived&.each do |name, block|
      struct_instance.define_singleton_method(name) { block.call(struct_instance) }
    end

  next if @conditions.any? { |cond| !cond.call(struct_instance) }

    yield struct_instance
  end
end

  def size
    return 0 unless @dimensions.is_a?(Hash)
    if @conditions.empty?
      values = @dimensions.values.map { |dim| dim.is_a?(Enumerable) ? dim.to_a : [dim] }
      return 0 if values.any?(&:empty?)
      values.map(&:size).inject(1, :*)
    else
      size = 0
      cartesian do |v|
        next if @conditions.any? { |cond| !cond.call(v) }
        size += 1
      end
      size
    end
  end

  def to_a(limit: nil)
    result = []
    cartesian do |v|
      result << v
      break if limit && result.size >= limit
    end
    result
  end

  def progress_each(lazy: false, title: "Processing")
    bar = ProgressBar.create(title: title, total: size, format: '%t [%B] %p%% %e')

    cartesian(@dimensions, lazy: lazy) do |v|
      yield v
      bar.increment
    end
  end

  def output(separator: " | ", colorize: false, align: true, format: :plain, limit: nil)
  rows = []
  cartesian do |v|
    rows << v
    break if limit && rows.size >= limit
  end
  return if rows.empty?

  headers = (
    rows.first.members +
    rows.first.singleton_methods(false).reject { |m| m.to_s.start_with?('__') }
  ).map(&:to_s)

  widths = align ? headers.to_h { |h|
    [h, [h.size, *rows.map { |r| fmt_cell(r.send(h), false).size }].max]
  } : {}

  case format
  when :markdown
    puts "| " + headers.map { |h| h.ljust(widths[h] || h.size) }.join(" | ") + " |"
    puts "|-" + headers.map { |h| "-" * (widths[h] || h.size) }.join("-|-") + "-|"
  when :csv
    puts headers.join(",")
  else
    puts headers.map { |h| fmt_cell(h, colorize, widths[h]) }.join(separator)
  end

  rows.each do |row|
    line = headers.map { |h| fmt_cell(row.send(h), colorize, widths[h]) }
    puts format == :csv ? line.join(",") : line.join(separator)
  end
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

private

  def fmt_cell(value, colorize, width = nil)
    str = case value
          when String then value
          else value.inspect
          end
    str = str.ljust(width) if width
    colorize ? str.colorize(:cyan) : str
  end
end

