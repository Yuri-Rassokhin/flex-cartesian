module FlexCartesianCore

def initialize(dimensions = nil, path: nil, format: :json, logger: nil, log_level: Logger::WARN)
    @logger = logger || Logger.new($stdout)
    @logger.level = log_level

    @logger.formatter = proc do |severity, _datetime, _progname, msg|
      "#{severity}: #{msg}\n"
    end

    if dimensions && path
      puts "Please specify either dimensions or path to dimensions"
      exit
    end

    @dimensions = dimensions
    @conditions = []
    @derived = {}
    @order = { first: nil, last: nil }
    @function_results = {}  # key: Struct instance.object_id => { fname => value }
    @function_hidden = Set.new
    import(path, format: format) if path
    @plan = nil
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
    bar = progress ? ProgressBar.create(title: title, total: size, format: '%t [%B] %p%% %e') : nil
    each_point do |v|
      @function_results[v] ||= {}
      @derived.each do |fname, block|
        @function_results[v][fname] = block.call(v)
      end
      bar&.increment
    end
  else
    raise ArgumentError, "Unknown command for function: #{command.inspect}"
  end
end

  # Wrapper on top of cartesian iterator
  # This wrapper decides whether we sweep over entire Cartesian space
  # or apply a plan to pick selected points only
  def each_point(&blk)
    if @plan
      @plan.each_point do |v|
        next unless valid?(v)
        blk.call(decorate_point(v))
      end
    else
      cartesian(&blk)
    end
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

    next unless valid?(struct_instance)

    yield struct_instance
  end
end

  def progress_each(lazy: false, title: "Processing")
    bar = ProgressBar.create(title: title, total: size, format: '%t [%B] %p%% %e')

    cartesian(@dimensions, lazy: lazy) do |v|
      yield v
      bar.increment
    end
  end



private

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

  # Test if `data` vector satisfies all space conditions
  def valid?(data)
    @conditions.none? { |cond| !cond.call(data) }
  end

  def log
    @logger
  end

end

