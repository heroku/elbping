
module ElbPing
  module Display
    # Format and display the ping data
    def self.response(status)
      node = status[:node]
      code = status[:code]
      duration = status[:duration]

      puts "Response from #{node}: code=#{code.to_s} time=#{duration} ms"
    end

    # Display summary of results (in aggregate and per-node)
    def self.summary(total_summary, node_summary)
      requests = total_summary[:reqs_attempted]
      responses = total_summary[:reqs_completed]
      loss = (1 - (responses.to_f/requests)) * 100

      latencies = total_summary[:latencies]
      avg_latency = (latencies.inject { |sum, el| sum + el }.to_f / latencies.size).to_i # ms

      puts '--- total statistics ---'
      puts "#{requests} requests, #{responses} responses, #{loss.to_i}% loss"
      puts "min/avg/max = #{latencies.min}/#{avg_latency}/#{latencies.max} ms"

      node_summary.each { |node, summary|
        requests = summary[:reqs_attempted]
        responses = summary[:reqs_completed]
        loss = (1 - (responses.to_f/requests)) * 100

        latencies = summary[:latencies]
        avg_latency = (latencies.inject { |sum, el| sum + el }.to_f / latencies.size).to_i # ms

        puts "--- #{node} statistics ---"
        puts "#{requests} requests, #{responses} responses, #{loss.to_i}% loss"
        puts "min/avg/max = #{latencies.min}/#{avg_latency}/#{latencies.max} ms"
      }
    end

  end
end

