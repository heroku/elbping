
require "net/http"
require "net/https"
require "openssl"

module ElbPing
  # Responsible for all HTTP ping-like functionality
  module HttpPinger

    # Extract CNs from a X509 subject string
    #
    # Arguments:
    # * x509_subject: (string) of cert subject

    def self.cert_name(x509_subject)
      cn_bucket = Array.new
      x509_subject.to_a.each do |entry|
        if entry.first == 'CN' and entry[1]
          cn_bucket << entry[1]
        end
      end
      cn_bucket
    end

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
      error, exc = nil, nil
      req, response, cert = nil, nil, nil

      begin
        http.start do
          req = ping_request.new(path)
          cert = http.peer_cert
          response = http.request(req)
        end
      rescue OpenSSL::SSL::SSLError => e
        # This probably? won't happen with VERIFY_NONE
        error = :sslerror
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

      ssl_status = {}
      if use_ssl
        raise "No cert when SSL enabled?!" unless cert
        ssl_status = {:sslSubject => cert_name(cert.subject),
          :sslExpires => cert.not_after}
      end

      {:code => error || response.code,
        :exception => exc,
        :node => node,
        :duration => ((Time.now.getutc - start) * 1000).to_i, # returns in ms
      }.merge(ssl_status)
    end
  end
end

