
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
      exc = nil
      begin
        response = http.request(ping_request.new(path))
      rescue Errno::ECONNREFUSED
        error = :econnrefused
      rescue Timeout::Error
        error = :timeout
      rescue Interrupt
        raise
      rescue SystemExit
        raise
      rescue StandardError => e
        exc = e # because I don't understand scope in ruby yet
        error = :exception
      end

      {:code => error || response.code,
        :exception => exc,
        :node => node,
        :duration => ((Time.now.getutc - start) * 1000).to_i} # returns in ms
    end
  end
end

