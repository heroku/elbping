
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
    #
    # TODO:
    # * Move calculations into ElbPing::Stats

    def self.summary(stats)
      total_summary, node_summary = stats.total, stats.nodes

      requests = total_summary[:reqs_attempted]
      responses = total_summary[:reqs_completed]
      latencies = total_summary[:latencies]
      # Calculate loss %
      loss = (1 - (responses.to_f/requests)) * 100

      # Calculate mean latency
      avg_latency = total_summary[:latencies].mean

      node_summary.each { |node, summary|
        requests = summary[:reqs_attempted]
        responses = summary[:reqs_completed]
        latencies = summary[:latencies]
        # Calculate loss % for this node
        loss = (1 - (responses.to_f/requests)) * 100

        # Calculate mean latency for this node
        avg_latency = node_summary[node][:latencies].mean

        self.out "--- #{node} statistics ---"
        self.out "#{requests} requests, #{responses} responses, #{loss.to_i}% loss"
        self.out "min/avg/max = #{latencies.min}/#{avg_latency}/#{latencies.max} ms"
      }

      self.out '--- total statistics ---'
      self.out "#{requests} requests, #{responses} responses, #{loss.to_i}% loss"
      self.out "min/avg/max = #{latencies.min}/#{avg_latency}/#{latencies.max} ms"
    end
  end
end
