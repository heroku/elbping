#!/usr/bin/env ruby

require 'optparse'
require 'uri'

require 'elbping/pinger.rb'
require 'elbping/resolver.rb'
require 'elbping/display.rb'
require 'elbping/stats.rb'

module ElbPing
  # Setup and initialization for running as a CLI app happens here. Specifically, on load it will
  # read in environment variables and set up default values for the app.
  module CLI

    # Set up default options
    OPTIONS = {}
    OPTIONS[:verb_len]      = ENV['PING_ELB_VERBLEN']       || 128
    OPTIONS[:nameserver]    = ENV['PING_ELB_NS']            || 'ns-941.amazon.com'
    OPTIONS[:count]         = ENV['PING_ELB_PINGCOUNT']     || 0
    OPTIONS[:timeout]       = ENV['PING_ELB_TIMEOUT']       || 10
    OPTIONS[:wait]          = ENV['PING_ELB_WAIT']          || 0

    # Build parser for command line options
    PARSER = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] <elb uri>"

      opts.on("-N NAMESERVER", "--nameserver NAMESERVER",
        "Use NAMESERVER to perform DNS queries (default: #{OPTIONS[:nameserver]})") do |ns|
        OPTIONS[:nameserver] = ns
      end
      opts.on("-L LENGTH", "--verb-length LENGTH", Integer,
        "Use verb LENGTH characters long (default: #{OPTIONS[:verb_len]})") do |n|
        OPTIONS[:verb_len] = n
      end
      opts.on("-W SECONDS", "--timeout SECONDS", Integer,
        "Use timeout of SECONDS for HTTP requests (default: #{OPTIONS[:timeout]})") do |n|
        OPTIONS[:timeout] = n
      end
      opts.on("-w SECONDS", "--wait SECONDS", Integer,
        "Wait SECONDS between pings (default: #{OPTIONS[:wait]})") do |n|
        OPTIONS[:wait] = n
      end
      opts.on("-c COUNT", "--count COUNT", Integer,
        "Ping each node COUNT times (default: #{OPTIONS[:count]})") do |n|
        OPTIONS[:count] = n
      end
    end

    # Displays usage
    def self.usage
      ElbPing::Display.out PARSER.help
      exit(false)
    end

    # Main entry point of the program. Specifically, this method will:
    #
    # * Parse and validate command line arguments
    # * Use the `ElbPing::Resolver` to discover ELB nodes
    # * Use the `ElbPing::HttpPinger` to ping ELB nodes
    # * Track the statistics for these pings
    # * And, finally, use call upon `ElbPing::Display` methods to output to stdout

    def self.main
      # Catch ctrl-c
      run = true
      trap("SIGINT") {
        run = false
      }

      ##
      # Parse and validate command line arguments
      PARSER.parse!(ARGV) rescue usage

      if ARGV.size < 1
        usage
      end

      unless ARGV[0] =~ URI::regexp
        ElbPing::Display.error "ELB URI does not seem valid"
        usage
      end

      elb_uri_s = ARGV[0]
      elb_uri = URI.parse(elb_uri_s)

      ##
      # Discover ELB nodes
      #
      # TODO: Perhaps some retry logic
      nameserver = OPTIONS[:nameserver]
      begin
        nodes = ElbPing::Resolver.find_elb_nodes elb_uri.host, nameserver
      rescue
        ElbPing::Display.error "Unable to query DNS for #{elb_uri.host} using #{nameserver}"
        exit(false)
      end

      if nodes.size < 1
        ElbPing::Display.error "Could not find any ELB nodes, no pings sent"
        exit(false)
      end

      ##
      # Set up summary objects for stats tracking of latency and loss
      stats = ElbPing::Stats.new
      nodes.each { |node| stats.add_node node }

      ##
      # Run the main loop of the program
      iteration = 0
      while run && (OPTIONS[:count] < 1 || iteration < OPTIONS[:count])

        sleep OPTIONS[:wait] if iteration > 0

        ##
        # Ping each node while tracking requests, responses, and latencies
        nodes.map { |node|
          status = ElbPing::HttpPinger.ping_node(node,
            elb_uri.port,
            (elb_uri.path == "") ? "/" : elb_uri.path,
            (elb_uri.scheme == 'https'),
            OPTIONS[:verb_len], OPTIONS[:timeout])

          # Display the response from the ping
          ElbPing::Display.response status

          # Register stats
          stats.register status
        }
        iteration += 1
      end
      # Display the stats summary
      ElbPing::Display.summary stats
    end
  end
end
