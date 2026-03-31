module FlexCartesianCore

  attr_reader :function_results, :derived, :names, :dimensiality, :dimensions, :struct, :levels

def initialize(dims = nil, path: nil, format: :json, logger: nil, log_level: Logger::WARN, source: nil, uri: nil, dimensions: nil)
    @logger = logger || Logger.new($stdout)
    @logger.level = log_level

    @logger.formatter = proc do |severity, _datetime, _progname, msg|
      "#{severity}: #{msg}\n"
    end

    # get hash of dimensions: name => array of dimensional values
    if dims && path
      raise "Cannot specify both dimensions and path to dimensions"
    elsif dims
      @dimensions = dims
    elsif path
      import(path, format: format)
    else
      # finally, we read entire space from URI
      raise "Missing data source type" if source.empty?
      raise "Missing data URI" if uri.empty?
      raise "Missing data dimensions" if dimensions.empty?
      index(source: source, uri: uri, dimensions: dimensions)
    end

    @dimensions = normalize_dimensions(@dimensions)
    # array of arrays of dimension values (not a Cartesian product yet)
    @levels = dimension_values(@dimensions)
    # total size of Cartesian space (number of vectors, that is, ALL combinations, ignoring conditions)
    @size = @levels.map(&:size).inject(:*)
    # array of dimension names
    @names = @dimensions.keys

    # define class for a vector represented as Struct, to be able to access its elements using `.<dimension_name>`
    # NOTE: this class must be unique - otherwise, Struct objects as Hash keys won't coincide for different Struct classes
    # even if fields of such structs are identical
    @struct = Struct.new(*@names).tap { |sc| sc.include(FlexOutput) }

    # number of dimensions of parameter space
    @dimensiality = @names.size

    # array of conditions for valid vectors in parameter space
    @conditions = []

    # functions in parameter space
    @derived = {}
    # ordering of the functions
    @order = { first: nil, last: nil }

    # Hash: instance of @struct class => { fname => value }
    @function_results = {}

    @function_hidden = Set.new

    # generate warnings on the deprecated things that will be changed/removed/replaced soon
    deprecations
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

def func(command = :print, name = nil, hide: false, progress: false, title: "calculating functions", order: nil, &block)
  case command
  when :add
    raise ArgumentError, "Function name and block required for :add" unless name && block_given?
    add_function(name, order: order, &block)
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
        order = ""
        if @order.value?(fname.to_sym)
          case @order.key(fname.to_sym)
          when :first
            order = " [FIRST]"
          when :last
            order = " [LAST]"
          end
        end
        puts "  #{fname.inspect.ljust(12)}| #{body}#{@function_hidden.include?(fname) ? ' [HIDDEN]' : ''}#{order}"
      end
    end

  when :run
    @function_results = {}
    cartesian(progress: progress, title: title) do |v|
      @function_results[v] ||= {}
      @derived.each do |fname, block|
        @function_results[v][fname] = block.call(v)
      end
    end
  else
    raise ArgumentError, "Unknown command for function: #{command.inspect}"
  end
end

def cartesian(dims = nil, lazy: false, progress: false, title: "Traversing space")

  # process edge cases and initialize data structures
  return to_enum(:cartesian, dims, lazy: lazy) unless block_given?
  dimensions = dims || @dimensions
  return nil unless dimensions.is_a?(Hash)

  # create actual cartesian product as iterator of all combinations
  values = dimension_values(dimensions)
  enum = Enumerator.product(*values) 
  space = lazy ? enum.lazy : enum

  # visualize progress bar, if requested
  bar = progress ? ProgressBar.create(title: title, total: @size, format: '%t [%B] %p%% %e') : nil

  space.each do |combination|
    # create current vector as Struct
    vector = @struct.new(*combination)
    # skip current vector if it doesn't satisfy space conditions
    next unless valid?(vector)

    # guarantee that functions can refer to one another within cartesian block
    @derived&.each do |name, block|
      vector.define_singleton_method(name) { block.call(vector) }
    end

    # process current vector as Struct
    yield vector

    # update progress bar, if it's enabled
    bar&.increment
  end
end

  # check if `v` is a valid vector in parameter space, with respect to space conditions
  # vector can be Struct, Hash, or Array. If it's Array, then order of dimensions is assumed from parameter space
  def valid?(v)
    # check if vector class is recognizable, and names & number of dimensions are aligned with parameter space
    return false unless vector_consistent?(v)
    # check if vector elements present among their respective dimensional values
    return false unless vector_to(v, :hash).each_pair.all? { |dim, v| @dimensions[dim].include?(v) }
    # check if vector respects conditions
    @conditions.none? { |cond| !cond.call(vector_to(v, :struct)) }
  end

# reads from target column using data source created by `data` method
def lookup(vector, target)
  key = v.values.map(&:to_s)
  index[key] ? index[key][target] : nil
end

# creates cartesian space and index from URI
def index(source:, uri:, dimensions:)
  @index = {}
  @dimensions ||= {}

  # заранее заводим все измерения
  dimensions.each do |dim|
    @dimensions[dim.to_sym] ||= []
  end

  case source
  when :csv
    require 'csv'
    table = CSV.read(uri, headers: true)

    table.each do |row|
      key = dimensions.map do |dim|
        value = row[dim.to_s]
        @dimensions[dim.to_sym] << value unless @dimensions[dim.to_sym].include?(value)
        value
      end

      @index[key] = row
    end

when :xlsx
  require 'roo'

  xlsx = Roo::Excelx.new(uri)
  sheet = xlsx.sheet(0)

  headers = sheet.row(1).map(&:to_s)

  (2..sheet.last_row).each do |i|
    row_values = sheet.row(i)

    # пропускаем пустые строки
    next if row_values.compact.empty?

    row = headers.zip(row_values).to_h

    key = dimensions.map do |dim|
      value = row[dim.to_s]

      # приводим к строке для консистентности с CSV
      value = value.to_s

      unless @dimensions[dim.to_sym].include?(value)
        @dimensions[dim.to_sym] << value
      end

      value
    end

    @index[key] = row
  end
else
  raise "Unknown source type #{source}"
end
self
end

# TODO: Dimensions can be omitted - in this case, automatically fetch all dimensions from CSV header
def data(command, source: nil, uri: nil, vector: nil, target: nil, dimensions: )
  case command
    when :get
      return nil if (vector.empty? or target.empty?)
      lookup(vector, target)
    else
      raise "Unknown data command #{command}"
  end
end



private

# convert dimensional values to array, for conformity
  def normalize_dimensions(dimensions)
    dimensions.transform_values do |values|
      values.is_a?(Enumerable) && !values.is_a?(String) ? values.to_a : [values]
    end
  end

  def dimension_values(dimensions)
    # array of arrays of dimensional values, not a cartesian product yet
    res = dimensions.values.map { |dim| dim.is_a?(Enumerable) ? dim.to_a : [dim] }
    # check if any dimension has no values
    res.each { |dim| raise "dimension cannot be empty: ``" if dim.empty? }
    res
  end

  def add_function(name, order: nil , &block)
    raise ArgumentError, "Block required" unless block_given?
    if reserved_function_names.include?(name.to_sym)
      raise ArgumentError, "Function name '#{name}' has been already added"
    elsif reserved_struct_names.include?(name.to_sym)
      raise ArgumentError, "Name '#{name}' has been reserved for internal method, you can't use it for a function"
    end
    if order == :last
      @derived[name.to_sym] = block # add to the tail of the hash
      @order[:last] = name.to_sym
    elsif order == :first
      @derived = { name.to_sym => block }.merge(@derived) # add to the head of the hash
      @order[:first] = name.to_sym
    elsif order == nil
      if @order[:last] != nil
        last_name = @order[:last]
        last_body = @derived[last_name]
        @derived.delete(@order[:last]) # remove the tail of the hash
        @derived[name.to_sym] = block # add new function to the tail of the hash
        @derived[last_name] = last_body # restore :last function in the tail of the hash
      else
        @derived[name.to_sym] = block
      end
    else
      raise ArgumentError, "unknown function order '#{order}'"
    end
  end

  def remove_function(name)
    @derived.delete(name.to_sym)
    @order[:last] = nil if @order[:last] == name.to_sym
    @order[:first] = nil if @order[:first] == name.to_sym
  end

  def reserved_struct_names
    (base_struct_methods = Struct.new(:dummy).methods(false) + Struct.new(:dummy).instance_methods(false)).uniq
  end

  def reserved_function_names
    (self.methods + self.class.instance_methods(false)).uniq
  end

  def decorate_point(v)
    @derived&.each do |name, block|
      v.define_singleton_method(name) { block.call(v) }
    end
    v
  end

  def log
    @logger
  end

  # convert Struct or Array vector to Hash, keeping order of dimension names as it is in parameter space
  # Note: conditions and dimension consistency are NOT respected
  def vector_to_hash!(v)
    return v if v.is_a?(Hash)

    if v.is_a?(Array)
      @names.zip(v).to_h
    elsif v.is_a?(Struct)
      v.members.zip(v.values).to_h
    else
      raise "Incorrect vector type `#{v.class}`"
    end
  end

  # convert Hash or Array vector to Struct, keeping order of dimension names as it is in parameter space
  # Note: conditions and dimension consistency are NOT respected
  def vector_to_struct!(v)
    return v if v.is_a?(Struct)

    if v.is_a?(Array)
      @struct.new(*v)
    elsif v.is_a?(Hash)
      @struct.new(*v.values)
    else
      raise "Incorrect vector type `#{v.class}`"
    end
  end

  # check consistency of the vector internal structure relatively to parameter space
  # Note: conditions are NOT checked
  def vector_consistent?(v)
    raise "Incorrect vector type `#{v.class}`" unless v.is_a?(Enumerable)
    raise "Incorrect dimensiality of vector '#{v.inspect}'" unless vector_to_hash!(v).size == @dimensiality
    raise "Incorrect vector dimensions #{v.keys.inspect}" unless @names.to_set == vector_to_hash!(v).keys.to_set
    true
  end

  # convert Struct or Array vector to Hash with all checks
  def vector_to(v, type)
    return nil unless vector_consistent?(v)

    case type
    when :hash
      vector_to_hash!(v)
    when :struct
      vector_to_struct!(v)
    else
      raise "Incorrect target type for vector conversion: #{type}"
    end
  end

end

