
# TODO: Needs unit tests

# An array for doing some basic stats on latencies (currently only mean)
class LatencyBucket < Array
  def sum
    self.inject { |sum, el| sum + el} || 0
  end

  def mean
    i = 0
    unless self.size == 0
      i = (self.sum.to_f / self.size).to_i
    end
  end
end
