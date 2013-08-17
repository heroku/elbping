
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

module ElbPing
  # Tracks the statistics of requests sent, responses received (hence loss) and latency
  class Stats

    attr_reader :total, :nodes

    def initialize
      @total = {
        :requests   =>  0,
        :responses  =>  0,
        :latencies  => LatencyBucket.new,
      }
      @nodes = {}
    end

    # Initializes stats buckets for a node if it doesn't already exist
    #
    # Arguments
    # * node: (string) IP of node

    def add_node(node)
      unless @nodes.keys.include? node
        @nodes[node] = {
          :requests   =>  0,
          :responses  =>  0,
          :latencies  => LatencyBucket.new,
        }
      end
    end

    # Registers stats following a ping
    #
    # Arguments:
    # * node: (string) IP of node
    # * status: (hash) Status object as returned from Pinger::ping_node

    def register(status)
      node = status[:node]
      # Register the node if it hasn't been already
      add_node node

      # Update requests sent regardless of errors
      @total[:requests] += 1
      @nodes[node][:requests] += 1

      # Don't update response counters or latencies if we encountered an error
      unless [:timeout, :econnrefused, :exception].include? status[:code]
        # Increment counters
        @total[:responses] += 1
        @nodes[node][:responses] += 1

        # Track latencies
        @total[:latencies] << status[:duration]
        @nodes[node][:latencies] << status[:duration]
      end
    end

    # Calculates loss across all nodes
    def total_loss
      calc_loss @total[:responses], @total[:requests]
    end

    # Calculates loss for a specific node
    #
    # Arguments:
    # * node: (string) IP of node
    #
    # TODO: Handle non-existent nodes

    def node_loss(node)
      calc_loss @nodes[node][:responses], @nodes[node][:requests]
    end

    private

    # Generic function to calculate loss as a per-1 float
    #
    # Arguments:
    # * responses: (number) How many responses were received (numerator)
    # * requests: (number) How many requests were sent (denominator)

    def calc_loss(responses, requests)
      1 - (responses.to_f/requests)
    end

  end
end

