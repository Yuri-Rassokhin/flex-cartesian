require 'ostruct'
require 'progressbar'
require 'colorize'
require 'json'
require 'yaml'
require 'method_source'
require 'set'

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

  def initialize(dimensions = nil, path: nil, format: :json)
    if dimensions && path
      $logger.msg "Please specify either dimensions or path to dimensions", :error
    end
    @dimensions = dimensions
    @conditions = []
    @derived = {}
    @function_results = {}  # key: Struct instance.object_id => { fname => value }
    @function_hidden = Set.new
    import(path, format: format) if path
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

def func(command = :print, name = nil, hide: false, progress: false, title: "calculating functions", &block)
  case command
  when :add
    raise ArgumentError, "Function name and block required for :add" unless name && block_given?
    add_function(name, &block)
    @function_hidden.delete(name.to_sym)
    @function_hidden << name.to_sym if hide

  when :del
    raise ArgumentError, "Function name required for :del" unless name
    remove_function(name)

  when :print
    if @derived.empty?
      puts "(no functions defined)"
    else
      @derived.each do |fname, fblock|
        source = fblock.source rescue '(source unavailable)'

        body = source.sub(/^.*?\s(?=(\{|\bdo\b))/, '').strip

        puts "  #{fname.inspect.ljust(12)}| #{body}#{@function_hidden.include?(fname) ? ' [HIDDEN]' : ''}"
      end
    end

  when :run
    @function_results = {}

    if progress
    bar = ProgressBar.create(title: title, total: size, format: '%t [%B] %p%% %e')

    cartesian do |v|
      @function_results[v] ||= {}
      @derived.each do |fname, block|
        @function_results[v][fname] = block.call(v)
      end
      bar.increment if progress
    end

  else
    cartesian do |v|
      @function_results[v] ||= {}
      @derived.each do |fname, block|
        @function_results[v][fname] = block.call(v)
      end
    end
  end

  else
    raise ArgumentError, "Unknown command for function: #{command.inspect}"
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

def output(separator: " | ", colorize: false, align: true, format: :plain, limit: nil, file: nil)
  rows = if @function_results && !@function_results.empty?
           @function_results.keys
         else
           result = []
           cartesian do |v|
             result << v
             break if limit && result.size >= limit
           end
           result
         end

  return if rows.empty?

  visible_func_names = @derived.keys - (@function_hidden || Set.new).to_a
  headers = rows.first.members.map(&:to_s) + visible_func_names.map(&:to_s)

  widths = align ? headers.to_h { |h|
    values = rows.map do |r|
      val = if r.members.map(&:to_s).include?(h)
              r.send(h)
            else
              @function_results&.dig(r, h.to_sym)
            end
      fmt_cell(val, false).size
    end
    [h, [h.size, *values].max]
  } : {}

  lines = []

  # Header
  case format
  when :markdown
    lines << "| " + headers.map { |h| h.ljust(widths[h] || h.size) }.join(" | ") + " |"
    lines << "|-" + headers.map { |h| "-" * (widths[h] || h.size) }.join("-|-") + "-|"
  when :csv
    lines << headers.join(",")
  else
    lines << headers.map { |h| fmt_cell(h, colorize, widths[h]) }.join(separator)
  end

  # Rows
  rows.each do |row|
    values = row.members.map { |m| row.send(m) } +
             visible_func_names.map { |fname| @function_results&.dig(row, fname) }

    line = headers.zip(values).map { |(_, val)| fmt_cell(val, colorize, widths[_]) }
    lines << (format == :csv ? line.join(",") : line.join(separator))
  end

  # Output to console or file
  if file
    File.write(file, lines.join("\n") + "\n")
  else
    lines.each { |line| puts line }
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

