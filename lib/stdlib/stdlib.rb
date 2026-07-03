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



end
