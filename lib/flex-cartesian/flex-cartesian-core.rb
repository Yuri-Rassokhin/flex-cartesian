module FlexCartesianCore

attr_reader :function_results, :derived, :names, :dimensiality, :dimensions, :struct, :levels, :index_show, :log

def index_show
  @index
end

def initialize(dims = nil, path: nil, format: :json, logger: nil, log_level: Logger::WARN, source: nil, uri: nil, dimensions: nil, separator: ',')
  init_logger(logger: logger, log_level: log_level)

  init_dimensions(dims, path: path, format: format, source: source, uri: uri, dimensions: dimensions, separator: separator)

  update_space_structures
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

def func(command = :print, *names, hide: false, progress: false, title: "Computing function(s)", order: nil, mode: :lazy, &block)
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
    # @function_results ||= {} # probably exccessive
    cartesian(progress: progress, title: title) { |v| functions_update_value(vector: v, functions: functions_found, mode: mode) }
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
  bar = progress ? ProgressBar.create(title: title, total: self.size, format: '%t [%B] %p%% %e') : nil

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
  unless @function_results.key?(vector) and @function_results[vector].key?(function)
    return substitute
  end
  @function_results[vector][function]
end

# reads from target column using data source created by `data` method
def lookup(vector, target)
  vec = vector_to(vector, :hash)
  return nil unless @index[vec]
  @index[vec][target.to_sym] ? @index[vec][target.to_sym] : @index[vec][target.to_s]
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
      key = dimensions.each_with_object({}) do |dim, hash|
        # TODO: XSLX values are converted to string for uniformity with CSV, even though XSLX returns proper types
        value = row[dim.to_s].to_s.strip
        dim_sym = dim.to_sym
        unless @dimensions_hash[dim_sym][value]
          @dimensions[dim_sym] << value
          @dimensions_hash[dim_sym][value] = true
        end
        hash[dim.to_sym]= value
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

def dim(command, *dims)
  case command
  when :add
    dims.each do |d|
      raise ArgumentError, "Incorrect description of the dimensions #{dims.inspect}, must be Hash" unless d.is_a?(Hash)
      @dimensions.update(d)
    end
    update_space_structures
  when :del
    dims.each do |dim|
      raise ArgumentError, "Incorrect dimension name #{dim.inspect}, must be Symbol" unless dim.is_a?(Symbol)
      @dimensions.delete(dim)
    end
    update_space_structures
  else
    raise "Incorrect dimension command: #{command}"
  end
end



private

# For a given array of dimension names, return those that are used in `block` as fields of its iterator
# This method provides a correctness check in the case we're removing dimensions
# It allows to determine the functions broken by the dimension removal
# NOTE: this check will miss any dependencies if executed from IRB

def func_check_dimension_deps(dimension_names)
  @derived.each do |func, body|
    deps = f_dimension_deps(body, dimension_names)
    @logger.error "Function `#{func}` depends on removed dimension(s): #{deps.join(', ')}" unless deps.empty?
  end
end

def f_dimension_deps(block, dimension_names)
  require 'ast'

  # Get AST of the function body
  ast = RubyVM::AbstractSyntaxTree.of(block)
  return [] unless ast

  # Get the name of iterator based on parameters of the block
  # block.parameters returns something like [[:opt, :v]] or [[:req, :vector]]
  # We simply take the first argument
  iterator_var_name = block.parameters.first&.last 
  return [] unless iterator_var_name

  found_dimensions = []

  # Traverse the AST recursively
  search = ->(node) do
    return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)

    # We are interested in :call only
    if node.type == :CALL
      receiver = node.children[0]     # Object called
      method_name = node.children[1]  # What method is called , such as :size

      # Main criteria:
      # - Object of the call exists
      # - It is a local variable :LVAR
      # - Its name is identical to the iterator's name, such as :v
      is_iterator_receiver = receiver && 
                             receiver.is_a?(RubyVM::AbstractSyntaxTree::Node) && 
                             [:LVAR, :DVAR].include?(receiver.type) && 
                             receiver.children[0] == iterator_var_name

      if is_iterator_receiver && dimension_names.include?(method_name)
        found_dimensions << method_name
      end
    end

    # Recursively traverse nested nodes
    node.children.each { |child| search.call(child) }
  end

  # Search and return unique findings
  search.call(ast)

  found_dimensions.uniq
end

# if dimensions were changed, update hash of function results, accordingly
def function_results_immerse
  return if @function_results.empty?

  # check if dimensions were added or removed
  change = @function_results.first.first.size - @dimensiality

  return if change == 0
  
  if change > 0
    # dimensions were removed
    removed_dimensions = @function_results.first.first.keys - @names
    func_check_dimension_deps(removed_dimensions)
    # NOTE: When we reduce dimensiality, then vectors as keys of function_results cease to be unique!
    # NOTE: As a new-unique vector key appear, Ruby just silently rewrite the same hash entry
    # NOTE: Having said this, only the _last_ function value will survive!
    @function_results.transform_keys! { |vector| vector.except(*removed_dimensions) }
  else
    # dimensions were added
    # as hash elements are added in order, to the end of hash, we take the `change` of last elements in @dimensiality
    # and - by agreement - we take the first dimensional values for each added dimension
    new_dimensions = @names - @function_results.first.first.keys
    # this is a hash of added dimensions with only first dimensional value for each dimension
    new_first_values = @dimensions.slice(*new_dimensions).transform_values!(&:first)
    # Immerse existing vectors to higher-dimensiality space by adding new dimensions with their first values
    # Note: this implies that existing functions will be defined in the immerse sub-space, and nil in the rest of the new space
    @function_results.transform_keys! { |vector| vector.merge(new_first_values) }
  end
end

# For a given subset of space functions, update their values in a given vector
def functions_update_value(vector: , functions: , mode: )
  v = vector_to(vector, :hash)
  @function_results[v] ||= {}

  functions.each do |fname, block|
    @function_results[v] ||= {}
    results = @function_results[v]

    case mode
    when :enforce
      results[fname] = block.call(vector)

    when :reuse
      unless results.key?(fname)
        raise ArgumentError, "Compute mode #{mode} requires function #{fname} to have value in #{vector_to(vector, :array).inspect}"
      end

    when :lazy
      unless results.key?(fname)
        results[fname] = block.call(vector)
      end

    else
      raise ArgumentError, "Incorrect computing mode #{mode.inspect}"
    end

    ensure_dimension_width(fname, results[fname])
  end
end

def update_space_structures
  update_dimensional_structures
  update_conditional_structures
  update_functional_structures
end 

def init_logger(logger:, log_level:)
  @logger = logger || Logger.new($stdout)
  @logger.level = log_level

  @logger.formatter = proc do |severity, _datetime, _progname, msg|
    "#{severity}: #{msg}\n"
  end

  # make this logger instance kill the program if severity is error or worse
  def @logger.add(severity, message = nil, progname = nil, &block)
    super
    raise SystemExit.new(1, message || progname) if severity >= Logger::ERROR
  end

end

def init_dimensions(dims, path:, format:, source:, uri:, dimensions:, separator:)
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
end

def update_dimensional_structures
  @dimensions = normalize_dimensions(@dimensions)

  # internal structure that allows us to quickly check if we're adding new or existing dimensional value
  # such hash is O(1) to the contrast with straightforward .include? which is O(n) and VERY slow on huge tables
  @dimensions_hash ||= Hash.new { |h, k| h[k] = {} }

  # array of arrays of dimension values (not a Cartesian product yet)
  @levels = dimension_values(@dimensions)
  # total size of Cartesian space (number of vectors, that is, ALL combinations, ignoring conditions)
  @raw_size = @levels.map(&:size).inject(:*)
  # array of dimension names
  @names = @dimensions.keys
  # internal structure: for each dimension, minimal textual width that fits all values in this dimension - required for table output
  # the width is determined for each actual dimension and for each function
  if @dimension_widths.nil?
    @dimension_widths = @names.zip(dimension_widths).to_h
  else
    @dimension_widths.update(@names.zip(dimension_widths).to_h)
  end
  # however, we must remove widths of removed dimensions or functions
#  @dimension_widths.keep_if { |k,_| @dimensions.key?(k) || @derived.key?(k) }
  @default_width = 10

  # define class for a vector represented as Struct, to be able to access its elements using `.<dimension_name>`
  # NOTE: this class must be unique - otherwise, Struct objects as Hash keys won't coincide for different Struct classes
  # even if fields of such structs are identical
  @struct = Struct.new(*@names).tap { |sc| sc.include(FlexOutput) }
  
  # number of dimensions of parameter space
  @dimensiality = @names.size
end

def update_conditional_structures
  # array of conditions for valid vectors in parameter space
  @conditions ||= []
end

def update_functional_structures
  # functions in parameter space
  @derived ||= {}
  # ordering of the functions
  @order ||= { first: nil, last: nil }
  # Hash: instance of @struct vector => { fname => value }
  @function_results ||= {}
  function_results_immerse
  @function_hidden ||= Set.new
end

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
    else
      value.to_s.size > @dimension_widths[name] # adding new value of a dynamic dimension
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

def add_dimension(dim)
  raise "Incorrect description of the dimension #{dim.inspect}, Hash required" unless dim.is_a(Hash)
  @dimensions << dim
end

end

