
# An array for doing some basic stats on latencies (currently only mean)
class LatencyBucket < Array
  def sum
    self.inject { |sum, el| sum + el} || 0
  end

  def mean
    if self.size == 0
      0
    else
      (self.sum.to_f / self.size).to_i
    end
  end
end
