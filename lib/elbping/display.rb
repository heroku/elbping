
module ElbPing
  # This is responsible for all things that send to stdout. It is mostly only used by `ElbPing::CLI`
  module Display

    # Print message to the screen. Mostly used in case someone ever wants to override it.
    #
    # Arguments:
    # * msg: (string) Message to display

    def self.out(msg)
      puts msg
    end

    # Print error message to the screen
    #
    # Arguments:
    # * msg: (string) Message to display

    def self.error(msg)
      self.out "ERROR: #{msg}"
    end

    # Print debug information to the screen
    #
    # Arguments:
    # * exception: (Exception object)

    def self.debug(exception)
      if ENV["DEBUG"]
        self.out "DEBUG: #{exception.backtrace}"
      end
    end

    # Format and display the ping data given a response
    #
    # Arguments:
    # * status: (hash) containing:
    #   * :node (string) IP address of node
    #   * :code (Fixnum || string || symbol) HTTP status code or symbol representing error during ping
    #   * :duration (Fixnum) Latency in milliseconds from ping
    #   * :exception (string, optional) Message to display from exception

    def self.response(status)
      node = status[:node]
      code = status[:code]
      duration = status[:duration]
      exc = status[:exception]
      exc_display = exc ? "exception=#{exc}" : ''

      self.out "Response from #{node}: code=#{code.to_s} time=#{duration} ms #{exc_display}"
    end

    # Display summary of requests, responses, and latencies (for aggregate and per-node)
    #
    # Arguments:
    # * stats: (ElbPing::Stats)

    def self.summary(stats)
      pinged_nodes = stats.nodes.keys.select { |n| stats.nodes[n][:requests] > 0 }
      pinged_nodes.each { |node|
        loss_pct = (stats.node_loss(node) * 100).to_i
        self.out "--- #{node} statistics ---"
        self.out "#{stats.nodes[node][:requests]} requests, #{stats.nodes[node][:responses]} responses, #{loss_pct}% loss"
        self.out "min/avg/max = #{stats.nodes[node][:latencies].min}/#{stats.nodes[node][:latencies].mean}/#{stats.nodes[node][:latencies].max} ms"
      }

      loss_pct = (stats.total_loss * 100).to_i
      self.out '--- total statistics ---'
      self.out "#{stats.total[:requests]} requests, #{stats.total[:responses]} responses, #{loss_pct}% loss"
      self.out "min/avg/max = #{stats.total[:latencies].min}/#{stats.total[:latencies].mean}/#{stats.total[:latencies].max} ms"
    end
  end
end
