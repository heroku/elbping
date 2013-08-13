
module ElbPing
  module Display
    # Format and display the ping data
    def self.response(status)
      node = status[:node]
      code = status[:code]
      duration = status[:duration]
      exc = status[:exception]
      exc_display = exc ? 'exception=#{exception}' : ''

      puts "Response from #{node}: code=#{code.to_s} time=#{duration} ms #{exc_display}"
    end

    # Display summary of results (in aggregate and per-node)
    def self.summary(total_summary, node_summary)
      requests = total_summary[:reqs_attempted]
      responses = total_summary[:reqs_completed]
      loss = (1 - (responses.to_f/requests)) * 100

      latencies = total_summary[:latencies]
      avg_latency = 0
      unless latencies.size == 0
        sum_latency = latencies.inject { |sum, el| sum + el} || 0
        avg_latency = (sum_latency.to_f / latencies.size).to_i # ms
      end

      node_summary.each { |node, summary|
        requests = summary[:reqs_attempted]
        responses = summary[:reqs_completed]
        loss = (1 - (responses.to_f/requests)) * 100

        latencies = summary[:latencies]
        avg_latency = 0
        unless latencies.size == 0
          sum_latency = latencies.inject { |sum, el| sum + el} || 0
          avg_latency = (sum_latency.to_f / latencies.size).to_i # ms
        end

        puts "--- #{node} statistics ---"
        puts "#{requests} requests, #{responses} responses, #{loss.to_i}% loss"
        puts "min/avg/max = #{latencies.min}/#{avg_latency}/#{latencies.max} ms"
      }

      puts '--- total statistics ---'
      puts "#{requests} requests, #{responses} responses, #{loss.to_i}% loss"
      puts "min/avg/max = #{latencies.min}/#{avg_latency}/#{latencies.max} ms"

    end

  end
end

