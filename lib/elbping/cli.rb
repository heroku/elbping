#!/usr/bin/env ruby

require 'optparse'
require 'uri'

require 'elbping/pinger.rb'
require 'elbping/resolver.rb'
require 'elbping/display.rb'

module ElbPing
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

    # Parse options
    def self.usage
      puts PARSER.help
      exit(false)
    end

    # Main entry point of the program
    def self.main
      PARSER.parse!(ARGV) rescue usage
      run = true

      # Catch ctrl-c
      trap("SIGINT") {
        run = false
      }

      if ARGV.size < 1
        usage
      end
      unless ARGV[0] =~ URI::regexp
        puts "ERROR: ELB URI does not seem valid"
        usage
      end
      elb_uri_s = ARGV[0]
      elb_uri = URI.parse(elb_uri_s)

      begin
        nodes = ElbPing::Resolver.find_elb_nodes(elb_uri.host,
          OPTIONS[:nameserver])
      rescue
        puts "Error querying DNS for #{elb_uri.host} (NS: #{OPTIONS[:nameserver]})"
        exit(false)
      end

      if nodes.size < 1
        puts "Could not find any ELB nodes, no pings sent."
        exit(false)
      end

      # Set up summary objects
      total_summary = {
        :reqs_attempted =>  0,
        :reqs_completed =>  0,
        :latencies      => [],
      }
      node_summary = {}
      nodes.each { |node| node_summary[node] = total_summary.clone }

      iteration = 0
      while (OPTIONS[:count] < 1 || iteration < OPTIONS[:count]) && run
        sleep OPTIONS[:wait] if iteration > 0

        nodes.map { |node|
          total_summary[:reqs_attempted] += 1
          node_summary[node][:reqs_attempted] += 1

          status = ElbPing::HttpPinger.ping_node(node,
            elb_uri.port,
            (elb_uri.path == "") ? "/" : elb_uri.path,
            (elb_uri.scheme == 'https'),
            OPTIONS[:verb_len], OPTIONS[:timeout])

          unless [:timeout, :econnrefused, :exception].include? status[:code]
            total_summary[:reqs_completed] += 1
            total_summary[:latencies] += [status[:duration]]
            node_summary[node][:reqs_completed] += 1
            node_summary[node][:latencies] += [status[:duration]]
          end

          ElbPing::Display.response(status)
        }
        iteration += 1
      end
      ElbPing::Display.summary(total_summary, node_summary)
    end
  end
end
