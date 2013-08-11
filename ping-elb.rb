#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'net/dns'
require "net/http"
require 'optparse'

$stderr.sync = true
$stdout.sync = true

# Set up default options
OPTIONS = {}
OPTIONS[:verb_len]      = ENV['PING_ELB_MAXVERBLEN']    || 128
OPTIONS[:nameserver]    = ENV['PING_ELB_NS']            || 'ns-941.amazon.com'
OPTIONS[:count]         = ENV['PING_ELB_PINGCOUNT']     || 4
OPTIONS[:timeout]       = ENV['PING_ELB_TIMEOUT']       || 10
OPTIONS[:wait]          = ENV['PING_ELB_WAIT']          || 0

# Build parser for command line options
PARSER = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] <elb hostname>"

  # -N _nameserver_
  opts.on("-N NAMESERVER", "--nameserver NAMESERVER", "Use NAMESERVER to perform DNS queries") do |ns|
    OPTIONS[:nameserver] = ns
  end

  # -L _verb length_
  opts.on("-L LENGTH", "--verb-length LENGTH", Integer, "Use verb LENGTH characters long") do |n|
    OPTIONS[:verb_len] = n
  end

  # -W _timeout_
  opts.on("-W SECONDS", "--timeout SECONDS", Integer, "Use timeout of SECONDS for HTTP requests") do |n|
    OPTIONS[:timeout] = n
  end

  # -w _wait_
  opts.on("-w SECONDS", "--wait SECONDS", Integer, "Wait SECONDS between pings (default: 0)") do |n|
    OPTIONS[:wait] = n
  end

  # -c _count_
  opts.on("-c COUNT", "--count COUNT", Integer, "Ping each node COUNT times") do |n|
    OPTIONS[:count] = n
  end
end

# Parse options
def usage
  puts PARSER.help
  exit(false)
end
PARSER.parse!(ARGV) rescue usage

# Resolve the nameserver hostname to a list of IP addresses
NS_ADDRS = Resolver(OPTIONS[:nameserver]).answer.map { |rr| rr.address.to_s }

# Define custom request method
class ElbPingRequest < Net::HTTPRequest
  METHOD = "A" * (OPTIONS[:verb_len])
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = false
end

# Make HTTP request to given node using custom request method
def ping_node(node, port=80, path="/")
  start = Time.now.getutc
  http = Net::HTTP.new(node, port.to_s)
  http.open_timeout     = OPTIONS[:timeout]
  http.read_timeout     = OPTIONS[:timeout]
  http.continue_timeout = OPTIONS[:timeout]
  http.ssl_timeout      = OPTIONS[:timeout] # untested

  error = nil
  response = http.request(ElbPingRequest.new(path)) rescue error = :timeout

  {:code => error || response.code,
    :node => node,
    :duration => ((Time.now.getutc - start) * 1000).to_i} # returns in ms
end

# Resolve an ELB address to a list of node IPs
def find_elb_nodes(target)
  resolver = Net::DNS::Resolver.new(
    :use_tcp => true,
    :nameservers => NS_ADDRS,
    :retry => 5)

  resp = resolver.query(target, Net::DNS::ANY)

  nodes = []
  resp.each_address { |a| nodes += [a.to_s] }
  nodes
end

# Format and display the ping data
def display_response(status)
  node = status[:node]
  code = status[:code]
  duration = status[:duration]

  puts "Response from #{node}: code=#{code.to_s} time=#{duration} ms"
end

# Display summary of results (in aggregate and per-node)
def display_summary(total_summary, node_summary)
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

# Main entry point of the program
def main
  if ARGV.size < 1
    usage
  end

  target = ARGV[0]
  nodes = find_elb_nodes(target)

  # Set up summary objects
  total_summary = {
    :reqs_attempted =>  0,
    :reqs_completed =>  0,
    :latencies      => [],
  }
  node_summary = {}
  nodes.each { |node| node_summary[node] = total_summary.clone }

  # Catch ctrl-c
  trap("INT") {
    display_summary(total_summary, node_summary)
    exit
  }

  (1..OPTIONS[:count]).each { |i|
    sleep OPTIONS[:wait] if i > 1

    nodes.map { |node|
      total_summary[:reqs_attempted] += 1
      node_summary[node][:reqs_attempted] += 1
      status = ping_node(node)

      unless status[:code] == :timeout
        total_summary[:reqs_completed] += 1
        total_summary[:latencies] += [status[:duration]]
        node_summary[node][:reqs_completed] += 1
        node_summary[node][:latencies] += [status[:duration]]
      end

      display_response(status)
    }
  }
  display_summary(total_summary, node_summary)
end

main

