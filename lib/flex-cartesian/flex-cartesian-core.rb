module FlexCartesianCore

  attr_reader :function_results, :derived, :names, :dimensiality, :dimensions, :struct, :levels, :index_show, :log

def index_show
  @index
end

def initialize(dims = nil, path: nil, format: :json, logger: nil, log_level: Logger::WARN, source: nil, uri: nil, dimensions: nil, separator: ',')
    @logger = logger || Logger.new($stdout)
    @logger.level = log_level

    @logger.formatter = proc do |severity, _datetime, _progname, msg|
      "#{severity}: #{msg}\n"
    end

    # internal structure that allows us to quickly check if we're adding new or existing dimensional value
    # such hash is O(1) to the contrast with straightforward .include? which is O(n) and VERY slow on huge tables
    @dimensions_hash = Hash.new { |h, k| h[k] = {} }

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
      index(source: source, uri: uri, dimensions: dimensions, separator: separator)
    end

    @dimensions = normalize_dimensions(@dimensions)
    # array of arrays of dimension values (not a Cartesian product yet)
    @levels = dimension_values(@dimensions)
    # total size of Cartesian space (number of vectors, that is, ALL combinations, ignoring conditions)
    @size = @levels.map(&:size).inject(:*)
    # array of dimension names
    @names = @dimensions.keys
    # internal structure: for each dimension, minimal textual width that fits all values in this dimension - required for table output
    @dimension_widths = @names.zip(dimension_widths).to_h
    @default_width = 10

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

    # Hash: instance of @struct vector => { fname => value }
    @function_results = {}

    @function_hidden = Set.new
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

def func(command = :print, *names, hide: false, progress: false, title: "Computing function(s)", order: nil, &block)
  case command

  when :add
    raise ArgumentError, "Function name required for :add" if names.empty?
    raise ArgumentError, "Block required for :add" unless block_given?
    @logger.warn "You are adding #{names.size} identical functions" if names.size > 1

    names.each do |name|
      add_function(name, order: order, &block)
      @function_hidden.delete(name.to_sym)
      @function_hidden << name.to_sym if hide
    end

  when :del
    raise ArgumentError, "Function name(s) required for :del" if names.empty?
    names.each do |name|
      remove_function(name)
    end

  when :print
    if @derived.empty?
      puts "(no functions defined)"
    else
      functions_found = names.empty? ? @derived : @derived.slice(*names)
      functions_missing = names.empty? ? [] : names - @derived.keys

      functions_found.each do |fname, fblock|
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

      functions_missing.each { |fname| puts "#{fname.inspect.ljust(12)}| (no function defined)" }
    end

  when :run
    functions_missing = names.empty? ? [] : names - @derived.keys
    raise "No function(s) defined: #{functions_missing.join(', ')}" unless functions_missing.empty?

    functions_found = names.empty? ? @derived : @derived.slice(*names)
    @function_results = {}

    cartesian(progress: progress, title: title) do |v|
      @function_results[v] ||= {}
      functions_found.each do |fname, block|
        value = block.call(v)
        @function_results[v][fname] = value
        ensure_dimension_width(fname, value)
      end
    end
  else
    raise ArgumentError, "Unknown command for function: #{command.inspect}"
  end
end

def cartesian(dims = nil, lazy: false, progress: false, title: "Iterating over parameter space")

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
    # skip current vector if it doesn't respect space conditions
    next unless fit?(vector)

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
  # this check is computationally aggressive and only makes sense for cmanually constructed vector
  def valid?(v)
    # DEBUG HERE
    # check if vector class is recognizable, and names & number of dimensions are aligned with parameter space
    return false unless vector_consistent?(v)
    # check if vector elements present among their respective dimensional values
    return false unless vector_to(v, :hash).each_pair.all? { |dim, v| @dimensions[dim].include?(v) }
    # check if vector respects conditions
    fit?(v)
  end

def fit?(v)
  @conditions.none? { |cond| !cond.call(vector_to(v, :struct)) }
end

def function(vector, function, substitute: 0)
  unless (@function_results[vector] and @function_results[vector][function])
    return substitute
  end
  @function_results[vector][function]
end

# reads from target column using data source created by `data` method
def lookup(vector, target)
  vec = vector_to(vector, :hash)
  tg = target.to_sym
  @index[vec] ? @index[vec][tg] : nil
end

# creates cartesian space and index from URI
# index is a hash that maps { dim1: value1, ..., dimN: valueN} to a row of the data source
def index(source:, uri:, dimensions:, separator: ',')
  @index = {}
  @dimensions ||= {}
  # initialize empty dimensions
  dimensions.each do |dim|
    @dimensions[dim.to_sym] ||= []
  end

  case source
  when :csv
    require 'csv'
    table = CSV.read(uri, headers: true, header_converters: :symbol, col_sep: separator, strip: true)

    table.each do |row|
      key = dimensions.each_with_object({}) do |dim, hash|
        value = row[dim].to_s.strip
        unless @dimensions_hash[dim][value]
          @dimensions[dim] << value
          @dimensions_hash[dim][value] = true
        end
       hash[dim.to_sym] = value
      end
      @index[key] = row
    end
  when :xlsx
    require 'roo'

    xlsx = Roo::Excelx.new(uri)
    sheet = xlsx.sheet(0)

    # each row is a hash of ALL columns from the XSLX
    data = sheet.parse(headers: true)
    # skip headers in the first row of XLSX sheet
    data.shift
    data.each do |row|
      next if row.values.all?(&:nil?)

      # index key is an array of dimensional values from the specified dimensions only
      # this key points to FULL row which is assumed to have values of the future functions
      key = dimensions.map do |dim|
        value = row[dim.to_s]
        dim_sym = dim.to_sym
        unless @dimensions_hash[dim_sym][value]
          @dimensions[dim_sym] << value
          @dimensions_hash[dim_sym][value] = true
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
def data(command, vector: nil, target: nil )
  case command
    when :get
      return nil if (vector.size == 0 or target.nil?)
      lookup(vector, target)
    else
      raise "Unknown data command #{command}"
  end
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



private

# create tabular widths for basic dimensions (that is, excluding functions)
def dimension_widths
  @dimensions.map do |dim, values|
    max_width = ([dim.to_s] + values).inject(0) do |max, e|
      len = e.to_s.length
      len > max ? len : max
    end
  end
end

# update tabular width of a dynamic dimension (i.e., function)
# to be called wherever you expect new dimension or a new dimensional value to appear
def ensure_dimension_width(name, value = nil)
  raise "Dimension name is empty" unless name

  if value == nil # adding new dynamic dimension with default width, if not added before
    @dimension_widths[name] = @default_width unless @dimension_widths[name]
  elsif value.to_s.size > @dimension_widths[name] # adding new value of a dynamic dimension
    @dimension_widths[name] = value.to_s.size
  end
end

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
  ensure_dimension_width(name)
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

end

