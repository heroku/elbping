
require "net/http"
require "net/https"

module ElbPing
  module HttpPinger
    # Make HTTP request to given node using custom request method
    def self.ping_node(node, port, path, use_ssl, verb_len, timeout)
      # Build request class
      ping_request = Class.new(Net::HTTPRequest) do
        const_set :METHOD, "A" * verb_len
        const_set :REQUEST_HAS_BODY, false
        const_set :RESPONSE_HAS_BODY, false
      end

      # Configure http object
      start = Time.now.getutc
      http = Net::HTTP.new(node, port.to_s)
      http.open_timeout     = timeout
      http.read_timeout     = timeout
      http.continue_timeout = timeout

      if use_ssl
        http.use_ssl          = true
        http.verify_mode      = OpenSSL::SSL::VERIFY_NONE
        http.ssl_timeout      = timeout
      end

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

