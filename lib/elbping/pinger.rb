
require "net/http"
require "net/https"

module ElbPing
  # Responsible for all HTTP ping-like functionality
  module HttpPinger

    # Make HTTP request to given node using custom request method and measure response time
    #
    # Arguments:
    # * node: (string) of node IP
    # * port: (string || Fixnum) of positive integer [1, 65535]
    # * path: (string) of path to request, e.g. "/"
    # * use_ssl: (boolean) Whether or not this is HTTPS
    # * verb_len: (Fixnum) of positive integer, how long the custom HTTP verb should be
    # * timeout: (Fixnum) of positive integer, how many _seconds_ for connect and read timeouts

    def self.ping_node(node, port, path, use_ssl, verb_len, timeout)
      ##
      # Build request class
      ping_request = Class.new(Net::HTTPRequest) do
        const_set :METHOD, "A" * verb_len
        const_set :REQUEST_HAS_BODY, false
        const_set :RESPONSE_HAS_BODY, false
      end

      ##
      # Configure http object
      start = Time.now.getutc
      http = Net::HTTP.new(node, port.to_s)
      http.open_timeout     = timeout
      http.read_timeout     = timeout
      http.continue_timeout = timeout

      # Enable SSL if it's to be used
      if use_ssl
        http.use_ssl          = true
        http.verify_mode      = OpenSSL::SSL::VERIFY_NONE
        http.ssl_timeout      = timeout
      end

      ##
      # Make the HTTP request and handle any errors along the way
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

