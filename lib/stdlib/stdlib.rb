module Stdlib



def self.average(v, default: 0.0)
  return default if v.empty?
  v.map(&:to_f).sum / v.size
end

def self.max(v, default: 0.0)
  return default if v.empty?
  v.map(&:to_f).max
end

def self.min(v, default: 0.0)
  return default if v.empty?
  v.map(&:to_f).min
end

def self.add_timing(space, probe: true, iteration: false, pbb: false)

  if probe
    space.func(:add, :time_probe, order: :first) { Time.now.strftime("%H:%M:%S - %d-%m-%Y") }
  end

  if pbb
    time_pbb = Time.now.strftime("%H:%M:%S - %d-%m-%Y")
    space.func(:add, :time_pbb, order: :first) { time_pbb }
  end

  time_iteration = {}
  if iteration
    space.func(:add, :time_iteration, order: :first) { |v| time_iteration[v.iteration] ||= Time.now.strftime("%H:%M:%S-%d:%m:%Y") }
  end
end



end
