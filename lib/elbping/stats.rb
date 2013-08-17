
module ElbPing
  # Tracks the statistics of requests sent, responses received (hence loss) and latency
  class Stats

    attr_reader :total, :nodes

    def initialize
      @total = {
        :reqs_attempted =>  0,
        :reqs_completed =>  0,
        :latencies      => [],
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
          :reqs_attempted =>  0,
          :reqs_completed =>  0,
          :latencies      => [],
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
      @total[:reqs_attempted] += 1
      @nodes[node][:reqs_attempted] += 1

      # Don't update response counters or latencies if we encountered an error
      unless [:timeout, :econnrefused, :exception].include? status[:code]
        @total[:reqs_completed] += 1
        @total[:latencies] += [status[:duration]]
        @nodes[node][:reqs_completed] += 1
        @nodes[node][:latencies] += [status[:duration]]
      end
    end
  end
end

