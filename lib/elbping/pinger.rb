
require "net/http"

module ElbPing
  module HttpPinger
    # Make HTTP request to given node using custom request method
    def self.ping_node(node, verb_len, timeout, port=80, path="/")

      ping_request = Class.new(Net::HTTPRequest) do
        const_set :METHOD, "A" * verb_len
        const_set :REQUEST_HAS_BODY, false
        const_set :RESPONSE_HAS_BODY, false
      end

      start = Time.now.getutc
      http = Net::HTTP.new(node, port.to_s)
      http.open_timeout     = timeout
      http.read_timeout     = timeout
      http.continue_timeout = timeout
      http.ssl_timeout      = timeout # untested

      error = nil
      response = http.request(ping_request.new(path)) rescue error = :timeout

      {:code => error || response.code,
        :node => node,
        :duration => ((Time.now.getutc - start) * 1000).to_i} # returns in ms
    end
  end
end

